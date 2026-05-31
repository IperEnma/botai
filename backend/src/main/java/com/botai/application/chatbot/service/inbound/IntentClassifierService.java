package com.botai.application.chatbot.service.inbound;

import com.botai.application.chatbot.dto.IntentClassification;
import com.botai.application.chatbot.prompt.BotPrompts;
import com.botai.application.chatbot.service.action.GetAgendaPublicUrlAction;
import com.botai.application.chatbot.service.action.ViewAgendaBookingsByContactAction;
import com.botai.application.chatbot.support.InboundTextHeuristics;
import com.botai.application.chatbot.service.action.ViewAgendaBookingsByContactAction;
import com.botai.application.chatbot.service.conversation.common.ConversationActionRouting;
import com.botai.domain.chatbot.feature.BotFeatures;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.LlmRequest;
import com.botai.domain.chatbot.model.LlmResponse;
import com.botai.domain.chatbot.service.BotAction;
import com.botai.domain.chatbot.service.LanguageModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Clasificador unificado: con {@link BotFeatures#AI_ENABLED} y modelo → mini-LLM (sin fallback a keywords);
 * si el mini-LLM falla → {@link IntentClassification.ServiceError}. Sin IA: regex de abuso y
 * {@link IntentClassification.GeneralQuestion} para FAQ/menú.
 * Tres rutas CRM frecuentes: información general ({@code PREGUNTA_GENERAL}), mis citas Agenda
 * ({@code view_agenda_bookings_by_contact}), reservar nueva cita ({@code get_agenda_public_url}; el id
 * legacy {@code book_appointment} se normaliza a esta acción).
 */
@Service
public class IntentClassifierService {

    private static final Logger log = LoggerFactory.getLogger(IntentClassifierService.class);

    private static final int LLM_MAX_TOKENS = 30;

    /**
     * Action ids CRM que deben figurar en el prompt del mini-LLM aunque no estén declarados como {@link BotAction} (p. ej. en BD).
     */
    private static final Set<String> EXTRA_CRM_ACTION_IDS = Set.of(
        "book_appointment",
        "get_agenda_public_url",
        "view_agenda_bookings_by_contact"
    );

    private static final List<Pattern> BAD_INTENT_PATTERNS = List.of(
        Pattern.compile("(?i)(idiota|imbécil|imbecil|estúpido|estupido|tonto|maldito|puta|puto|jodete|vete\\s+a\\s+la\\s+mierda)"),
        Pattern.compile("(?i)(fuck\\s+you|damn\\s+you|you\\s+suck|piece\\s+of\\s+shit)"),
        Pattern.compile("(?i)(te\\s+voy\\s+a\\s+matar|te\\s+mat(o|é)|los\\s+voy\\s+a\\s+matar)")
    );

    private final Optional<LanguageModel> languageModel;
    private final FeatureFlagService featureFlagService;
    private final Set<String> validActionIds;

    public IntentClassifierService(List<BotAction> actions,
                                   Optional<LanguageModel> languageModel,
                                   FeatureFlagService featureFlagService) {
        LinkedHashMap<String, String> fromBots = new LinkedHashMap<>();
        if (actions != null) {
            for (BotAction a : actions) {
                String trigger = a.getTriggerIntent();
                if (trigger != null && !trigger.isBlank()) {
                    fromBots.put(trigger.strip().toLowerCase(), a.getActionId());
                }
            }
        }
        this.validActionIds = new HashSet<>(fromBots.values());
        this.validActionIds.addAll(EXTRA_CRM_ACTION_IDS);
        this.languageModel = languageModel != null ? languageModel : Optional.empty();
        this.featureFlagService = featureFlagService;
        log.info("[CLASSIFIER] actions={}", validActionIds);
    }

    public IntentClassification classify(String text, String tenantId) {
        return classify(text, tenantId, null);
    }

    /**
     * Con IA: regex de abuso → mini-LLM; fallo o respuesta no parseable → {@link IntentClassification.ServiceError} (sin keywords).
     * Sin IA: regex de abuso → {@link IntentClassification.GeneralQuestion} (FAQ/menú en el handler).
     */
    public IntentClassification classify(String text, String tenantId, ConversationState conversationState) {
        if (text == null || text.isBlank()) {
            return new IntentClassification.GeneralQuestion();
        }
        String normalized = text.strip().toLowerCase();
        boolean useLlmForTenant = tenantId != null && !tenantId.isBlank()
            && featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)
            && languageModel.isPresent();

        if (matchesBadIntentRegex(normalized)) {
            return new IntentClassification.BadIntent();
        }

        if (!useLlmForTenant) {
            return new IntentClassification.GeneralQuestion();
        }

        if (InboundTextHeuristics.looksLikeViewAgendaBookings(text)) {
            log.info("[CLASSIFIER] Heuristica mis citas -> view_agenda_bookings_by_contact");
            return new IntentClassification.CrmAction(ViewAgendaBookingsByContactAction.ACTION_ID);
        }
        if (InboundTextHeuristics.looksLikeNewBookingRequest(text)) {
            log.info("[CLASSIFIER] Heuristica reserva nueva -> get_agenda_public_url");
            return new IntentClassification.CrmAction(GetAgendaPublicUrlAction.ACTION_ID);
        }

        IntentClassification fromLlm = classifyWithLlm(text, conversationState);
        if (fromLlm != null) {
            if (fromLlm.isBadIntent() && InboundTextHeuristics.looksLikeNoiseOrCorruptedContent(text)) {
                log.info("[CLASSIFIER] MALA_INTENCION anulada (ruido/encoding) -> PREGUNTA_GENERAL");
                return new IntentClassification.GeneralQuestion();
            }
            return normalizeAgendaBookingIntent(fromLlm);
        }
        log.warn("[CLASSIFIER] Mini-LLM no clasificó -> ServiceError (sin fallback a keywords)");
        return new IntentClassification.ServiceError();
    }

    /**
     * Unifica reservas nuevas en la acción que devuelve el enlace público de Agenda (menús legacy pueden seguir
     * etiquetando {@code book_appointment}).
     */
    private static IntentClassification normalizeAgendaBookingIntent(IntentClassification c) {
        if (!c.isCrmAction()) {
            return c;
        }
        Optional<String> id = c.getActionId();
        if (id.isPresent() && ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(id.get())) {
            return new IntentClassification.CrmAction(GetAgendaPublicUrlAction.ACTION_ID);
        }
        return c;
    }

    private String classifierActionListForPrompt() {
        List<String> ids = new ArrayList<>(validActionIds);
        ids.remove(ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID);
        Collections.sort(ids);
        return String.join(", ", ids);
    }

    private static boolean matchesBadIntentRegex(String normalized) {
        for (Pattern p : BAD_INTENT_PATTERNS) {
            if (p.matcher(normalized).find()) {
                return true;
            }
        }
        return false;
    }

    private IntentClassification classifyWithLlm(String text, ConversationState state) {
        try {
            String actionList = classifierActionListForPrompt();
            List<String> systemLines = new ArrayList<>(BotPrompts.IntentClassifier.llmSystemLines(actionList));
            String prompt = BotPrompts.IntentClassifier.llmUserPrompt(text);
            LlmRequest request = new LlmRequest(prompt, systemLines, List.of(), LLM_MAX_TOKENS);
            LlmResponse response = languageModel.get().generate(request);
            if (!response.isSuccess()) {
                log.error("[CLASSIFIER] LLM error: {}", response.getErrorMessage());
                return null;
            }
            String raw = response.getText();
            if (raw == null || raw.isBlank()) {
                log.error("[CLASSIFIER] LLM devolvió respuesta vacía");
                return null;
            }
            return parseLlmClassification(raw.strip());
        } catch (Exception e) {
            log.error("[CLASSIFIER] LLM exception: {} — {}", e.getMessage(), e.getClass().getSimpleName(), e);
            return null;
        }
    }

    private IntentClassification parseLlmClassification(String raw) {
        String line = raw.strip();
        if (line.startsWith("```")) {
            line = line.substring(3).strip();
            if (line.endsWith("```")) {
                line = line.substring(0, line.length() - 3).strip();
            }
        }
        int nl = line.indexOf('\n');
        if (nl >= 0) {
            line = line.substring(0, nl).strip();
        }
        line = line.toUpperCase();
        if (line.contains("MALA_INTENCION") || line.contains("MALA_INTENCIÓN")) {
            return new IntentClassification.BadIntent();
        }
        if (line.contains("SALUDO")) {
            return new IntentClassification.Greeting();
        }
        if (line.contains("PREGUNTA_GENERAL") || (line.contains("PREGUNTA") && line.contains("GENERAL"))) {
            return new IntentClassification.GeneralQuestion();
        }
        if (line.contains("ACCION_CRM")) {
            List<String> byLength = new ArrayList<>(validActionIds);
            if (!validActionIds.contains("view_appointments")) {
                byLength.add("view_appointments");
            }
            byLength.sort((a, b) -> Integer.compare(b.length(), a.length()));
            for (String actionId : byLength) {
                if (line.contains(actionId.toUpperCase().replace('_', ' ')) || line.contains(actionId.toUpperCase())) {
                    String canonical = normalizeCrmActionId(actionId);
                    log.info("[CLASSIFIER] LLM -> CRM action: {} (canonical: {})", actionId, canonical);
                    return new IntentClassification.CrmAction(canonical);
                }
            }
            return new IntentClassification.GeneralQuestion();
        }
        return null;
    }

    public Optional<String> classifyActionIntent(String text, String tenantId) {
        return classify(text, tenantId).getActionId();
    }

    private static String normalizeCrmActionId(String actionId) {
        if ("view_appointments".equals(actionId)) {
            return ViewAgendaBookingsByContactAction.ACTION_ID;
        }
        if (ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(actionId)) {
            return GetAgendaPublicUrlAction.ACTION_ID;
        }
        return actionId;
    }
}
