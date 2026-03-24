package com.botai.chatbot.application.service.inbound;

import com.botai.chatbot.application.dto.IntentClassification;
import com.botai.chatbot.application.prompt.BotPrompts;
import com.botai.chatbot.application.support.InboundTextHeuristics;
import com.botai.chatbot.application.service.conversation.common.ConversationActionRouting;
import com.botai.chatbot.domain.feature.BotFeatures;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.LlmRequest;
import com.botai.chatbot.domain.model.LlmResponse;
import com.botai.chatbot.domain.service.BotAction;
import com.botai.chatbot.domain.service.LanguageModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Clasificador unificado: con {@link BotFeatures#AI_ENABLED} y modelo → mini-LLM (sin fallback a keywords);
 * si el mini-LLM falla → {@link IntentClassification.ServiceError}, salvo si hay cita activa (se usa
 * {@link IntentClassification.GeneralQuestion} para no cortar el hilo). Sin IA: regex de abuso y
 * {@link IntentClassification.GeneralQuestion} para FAQ/menú.
 * Con {@code book_appointment} activo: solo documento (dígitos), fricción benigna y texto ruido/encoding ({@code ???}, U+FFFD) no dejan MALA_INTENCION cortar el hilo.
 */
@Service
public class IntentClassifierService {

    private static final Logger log = LoggerFactory.getLogger(IntentClassifierService.class);

    private static final int LLM_MAX_TOKENS = 30;

    /**
     * Action ids CRM que deben figurar en el prompt del mini-LLM aunque no estén declarados como {@link BotAction} (p. ej. en BD).
     */
    private static final Set<String> EXTRA_CRM_ACTION_IDS = Set.of(
        "view_appointments",
        "book_appointment"
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

        if (isActiveBookAppointment(conversationState) && looksLikeSoloDocumentoOCedula(text)) {
            log.info("[CLASSIFIER] Cita activa + solo documento/cédula -> ACCION_CRM book_appointment (sin mini-LLM)");
            return new IntentClassification.CrmAction(ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID);
        }

        IntentClassification fromLlm = classifyWithLlm(text, conversationState);
        if (fromLlm != null) {
            if (fromLlm.isBadIntent() && InboundTextHeuristics.looksLikeNoiseOrCorruptedContent(text)) {
                if (isActiveBookAppointment(conversationState)) {
                    log.info("[CLASSIFIER] MALA_INTENCION anulada (ruido/encoding) -> ACCION_CRM book_appointment");
                    return new IntentClassification.CrmAction(ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID);
                }
                log.info("[CLASSIFIER] MALA_INTENCION anulada (ruido/encoding) -> PREGUNTA_GENERAL");
                return new IntentClassification.GeneralQuestion();
            }
            if (fromLlm.isBadIntent() && isActiveBookAppointment(conversationState)
                && looksLikeBenignBookingFriction(text)) {
                log.info("[CLASSIFIER] MALA_INTENCION anulada (fricción agendamiento) -> PREGUNTA_GENERAL");
                return new IntentClassification.GeneralQuestion();
            }
            return fromLlm;
        }
        if (isActiveBookAppointment(conversationState)) {
            log.warn("[CLASSIFIER] Mini-LLM no clasificó con cita activa -> PREGUNTA_GENERAL (mantiene hilo)");
            return new IntentClassification.GeneralQuestion();
        }
        log.warn("[CLASSIFIER] Mini-LLM no clasificó -> ServiceError (sin fallback a keywords)");
        return new IntentClassification.ServiceError();
    }

    private static boolean isActiveBookAppointment(ConversationState state) {
        return state != null && state.hasIntent()
            && ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(state.getCurrentIntent());
    }

    /** Respuesta típica con solo documento o cédula (sin letras). */
    private static boolean looksLikeSoloDocumentoOCedula(String text) {
        if (text == null || text.isBlank()) {
            return false;
        }
        String compact = text.strip().replaceAll("[\\s.\\-]", "");
        if (compact.length() < 5 || compact.length() > 14) {
            return false;
        }
        return compact.chars().allMatch(Character::isDigit);
    }

    /** Reclamos o correcciones leves durante el agendamiento; no deben ir a mala intención. */
    private static boolean looksLikeBenignBookingFriction(String text) {
        if (text == null || text.isBlank()) {
            return false;
        }
        String n = text.strip().toLowerCase();
        if (n.length() > 160) {
            return false;
        }
        return n.contains("no me llamo") || n.contains("no me llamó") || n.contains("no me llamas")
            || n.contains("no dije") || n.contains("no dijiste") || n.contains("ya dije") || n.contains("te dije")
            || n.contains("pero ") || n.startsWith("pero ") || n.contains("ya te") || n.contains("sinya")
            || n.contains("equivoc") || n.contains("nombre") || n.contains("repite") || n.contains("preguntaste")
            || n.contains("fecha y el servicio") || n.contains("fecha y servicio");
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
            String actionList = String.join(", ", validActionIds);
            List<String> systemLines = new ArrayList<>(BotPrompts.IntentClassifier.llmSystemLines(actionList));
            if (state != null && state.hasIntent()
                && ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(state.getCurrentIntent())) {
                systemLines.addAll(BotPrompts.IntentClassifier.activeBookAppointmentClassifierContextLines());
                log.debug("[CLASSIFIER] Mini-LLM con contexto de continuación book_appointment");
            }
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
            byLength.sort((a, b) -> Integer.compare(b.length(), a.length()));
            for (String actionId : byLength) {
                if (line.contains(actionId.toUpperCase().replace('_', ' ')) || line.contains(actionId.toUpperCase())) {
                    log.info("[CLASSIFIER] LLM -> CRM action: {}", actionId);
                    return new IntentClassification.CrmAction(actionId);
                }
            }
            return new IntentClassification.GeneralQuestion();
        }
        return null;
    }

    public Optional<String> classifyActionIntent(String text, String tenantId) {
        return classify(text, tenantId).getActionId();
    }
}
