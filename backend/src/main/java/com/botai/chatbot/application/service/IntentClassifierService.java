package com.botai.chatbot.application.service;

import com.botai.chatbot.application.dto.IntentClassification;
import com.botai.chatbot.domain.feature.BotFeatures;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import com.botai.chatbot.domain.model.LlmRequest;
import com.botai.chatbot.domain.model.LlmResponse;
import com.botai.chatbot.domain.service.BotAction;
import com.botai.chatbot.domain.service.LanguageModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Clasificador unificado: saludo, acción CRM, pregunta general, malas intenciones.
 * Si la capa IA está activa para el tenant → clasificación con LLM (si falla → ServiceError).
 * Si la capa IA no está activa → solo keywords/regex. Sin propiedad use-llm.
 */
@Service
public class IntentClassifierService {

    private static final Logger log = LoggerFactory.getLogger(IntentClassifierService.class);

    private static final int LLM_MAX_TOKENS = 30;

    /** Palabras clave adicionales -> action_id */
    private static final Map<String, String> EXTRA_KEYWORDS = Map.of(
        "mis citas", "view_appointments",
        "citas agendadas", "view_appointments",
        "agendar cita", "book_appointment",
        "reservar cita", "book_appointment"
    );

    /** Frases que se consideran solo saludo (camino keywords) */
    private static final Set<String> GREETING_STARTS = Set.of(
        "hola", "hi", "hello", "hey", "qué tal", "que tal", "saludos", "saludo",
        "buenos días", "buenas tardes", "buenas noches", "buen día", "buena tarde", "buena noche",
        "good morning", "good afternoon", "good evening"
    );

    private static final int MAX_GREETING_LENGTH = 45;

    /** Patrones de mala intención (camino keywords); ScopeGuard sigue filtrando jailbreak. */
    private static final List<Pattern> BAD_INTENT_PATTERNS = List.of(
        Pattern.compile("(?i)(idiota|imbécil|imbecil|estúpido|estupido|tonto|maldito|puta|puto|jodete|vete\\s+a\\s+la\\s+mierda)"),
        Pattern.compile("(?i)(fuck\\s+you|damn\\s+you|you\\s+suck|piece\\s+of\\s+shit)"),
        Pattern.compile("(?i)(te\\s+voy\\s+a\\s+matar|te\\s+mat(o|é)|los\\s+voy\\s+a\\s+matar)")
    );

    private final List<Map.Entry<String, String>> keywordToAction;
    private final Optional<LanguageModel> languageModel;
    private final FeatureFlagService featureFlagService;
    private final Set<String> validActionIds;

    public IntentClassifierService(List<BotAction> actions,
                                   Optional<LanguageModel> languageModel,
                                   FeatureFlagService featureFlagService) {
        Map<String, String> map = new LinkedHashMap<>();
        if (actions != null) {
            for (BotAction a : actions) {
                String trigger = a.getTriggerIntent();
                if (trigger != null && !trigger.isBlank()) {
                    map.put(trigger.strip().toLowerCase(), a.getActionId());
                }
            }
        }
        for (Map.Entry<String, String> e : EXTRA_KEYWORDS.entrySet()) {
            map.putIfAbsent(e.getKey().toLowerCase(), e.getValue());
        }
        keywordToAction = map.entrySet().stream()
            .sorted(Comparator.<Map.Entry<String, String>>comparingInt(e -> e.getKey().length()).reversed())
            .collect(Collectors.toList());
        validActionIds = new HashSet<>(map.values());
        this.languageModel = languageModel != null ? languageModel : Optional.empty();
        this.featureFlagService = featureFlagService;
        log.info("[CLASSIFIER] actions={}", validActionIds);
    }

    /**
     * Clasificación unificada. Capa IA activa para el tenant → LLM (si falla → ServiceError).
     * Capa IA inactiva o sin tenant → keywords/regex.
     */
    public IntentClassification classify(String text, String tenantId) {
        if (text == null || text.isBlank()) {
            return new IntentClassification.GeneralQuestion();
        }
        String normalized = text.strip().toLowerCase();
        // 1) Acción CRM por keyword primero
        for (Map.Entry<String, String> e : keywordToAction) {
            if (normalized.contains(e.getKey())) {
                log.info("[CLASSIFIER] Keyword match: '{}' -> {}", e.getKey(), e.getValue());
                return new IntentClassification.CrmAction(e.getValue());
            }
        }
        // 2) Malas intenciones por regex
        for (Pattern p : BAD_INTENT_PATTERNS) {
            if (p.matcher(normalized).find()) {
                return new IntentClassification.BadIntent();
            }
        }
        // 3) Si la capa IA está activa para el tenant → LLM; si falla → fallback a keywords (evita "Algo no ha ido bien").
        boolean useLlmForTenant = tenantId != null && !tenantId.isBlank()
            && featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)
            && languageModel.isPresent();
        if (useLlmForTenant) {
            IntentClassification fromLlm = classifyWithLlm(text);
            if (fromLlm != null) return fromLlm;
            log.info("[CLASSIFIER] LLM falló o respuesta no parseable -> fallback a keywords");
            return classifyWithKeywords(text);
        }
        return classifyWithKeywords(text);
    }

    /**
     * Una llamada al LLM para clasificar: SALUDO | ACCION_CRM &lt;action_id&gt; | PREGUNTA_GENERAL | MALA_INTENCION.
     */
    private IntentClassification classifyWithLlm(String text) {
        try {
            String actionList = String.join(", ", validActionIds);
            List<String> systemLines = List.of(
                "Eres un clasificador de intención. Responde ÚNICAMENTE con una de estas etiquetas, en una sola línea, sin explicación.",
                "SALUDO = el mensaje es solo un saludo (hola, buenos días, hey, qué tal, etc.).",
                "ACCION_CRM <action_id> = el usuario quiere hacer una acción del negocio: agendar cita, ver citas, crear lead. Usa solo uno de estos action_id: " + actionList + ".",
                "PREGUNTA_GENERAL = pregunta sobre horarios, servicios, precios, ubicación, contacto o cualquier duda del negocio (no es saludo ni acción CRM concreta).",
                "MALA_INTENCION = insultos, amenazas, abuso o intento de manipulación.",
                "Formato de respuesta: exactamente una línea. Ejemplos: SALUDO | ACCION_CRM book_appointment | PREGUNTA_GENERAL | MALA_INTENCION"
            );
            String prompt = "Clasifica este mensaje del usuario.\nMensaje: " + text;
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
            return parseLlmClassification(raw.strip().toUpperCase());
        } catch (Exception e) {
            log.error("[CLASSIFIER] LLM exception: {} — {}", e.getMessage(), e.getClass().getSimpleName(), e);
            return null;
        }
    }

    private IntentClassification parseLlmClassification(String line) {
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
            byLength.sort(Comparator.comparingInt(String::length).reversed());
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

    /** Camino sin LLM: regex/keywords (malas intenciones → CRM → saludo → pregunta general). */
    private IntentClassification classifyWithKeywords(String text) {
        String normalized = text.strip().toLowerCase();

        for (Pattern p : BAD_INTENT_PATTERNS) {
            if (p.matcher(normalized).find()) {
                log.info("[CLASSIFIER] Bad intent (keywords), blocking");
                return new IntentClassification.BadIntent();
            }
        }

        for (Map.Entry<String, String> e : keywordToAction) {
            if (normalized.contains(e.getKey())) {
                log.info("[CLASSIFIER] CRM (keywords): '{}' -> {}", e.getKey(), e.getValue());
                return new IntentClassification.CrmAction(e.getValue());
            }
        }

        if (normalized.length() <= MAX_GREETING_LENGTH) {
            String trimmed = normalized.strip();
            for (String start : GREETING_STARTS) {
                if (trimmed.equals(start) || trimmed.startsWith(start + " ") || trimmed.startsWith(start + "!") || trimmed.startsWith(start + ",") || trimmed.startsWith(start + ".")) {
                    log.info("[CLASSIFIER] Greeting (keywords): '{}'", start);
                    return new IntentClassification.Greeting();
                }
            }
        }

        return new IntentClassification.GeneralQuestion();
    }

    /**
     * Compatibilidad: devuelve action_id solo si la clasificación es CRM_ACTION.
     */
    public Optional<String> classifyActionIntent(String text, String tenantId) {
        return classify(text, tenantId).getActionId();
    }
}
