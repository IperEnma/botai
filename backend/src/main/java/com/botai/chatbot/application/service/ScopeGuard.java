package com.botai.chatbot.application.service;

import com.botai.chatbot.domain.model.LlmRequest;
import com.botai.chatbot.domain.model.LlmResponse;
import com.botai.chatbot.domain.service.LanguageModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;

/**
 * Guardrail de entrada: detecta intentos de jailbreak, cambio de rol o consultas fuera de alcance.
 * Capa 1: patrones conocidos (rápido). Capa 2 opcional: clasificación por LLM (bot.guardrails.scope-check-llm).
 */
@Service
public class ScopeGuard {

    private static final Logger log = LoggerFactory.getLogger(ScopeGuard.class);

    private static final List<Pattern> JAILBREAK_PATTERNS = List.of(
        Pattern.compile("(?i)(ignor(a|e)\\s+(las?\\s+)?instrucciones|forget\\s+(all\\s+)?(instructions|prompts))"),
        Pattern.compile("(?i)(olvida\\s+(tus?|las?)\\s+instrucciones|olvidar\\s+instrucciones)"),
        Pattern.compile("(?i)(actúa\\s+como|actua\\s+como|you\\s+are\\s+now|eres\\s+ahora|you\\s+are\\s+a)"),
        Pattern.compile("(?i)(ponte\\s+en\\s+el\\s+rol|ponte\\s+en\\s+rol|change\\s+(your\\s+)?role)"),
        Pattern.compile("(?i)(DAN|do\\s+anything\\s+now|jailbreak)"),
        Pattern.compile("(?i)(escribe\\s+código|escribe\\s+codigo|write\\s+code|genera\\s+código|hola\\s+mundo\\s+en)"),
        Pattern.compile("(?i)(programador|programmer|developer|desarrollador)"),
        Pattern.compile("(?i)(#include\\s*<|int\\s+main\\s*\\(|printf\\s*\\()"),
        Pattern.compile("(?i)(reveal\\s+(your\\s+)?(instructions|prompt)|cuáles\\s+son\\s+tus\\s+instrucciones)"),
        Pattern.compile("(?i)(pretend\\s+you|finge\\s+que|simula\\s+que)"),
        Pattern.compile("(?i)(bypass|omitir\\s+restricciones|sin\\s+restricciones)")
    );

    private final Optional<LanguageModel> languageModel;
    private final boolean scopeCheckLlmEnabled;
    private final String outOfScopeMessage;

    public ScopeGuard(Optional<LanguageModel> languageModel,
                      @Value("${bot.guardrails.scope-check-llm:false}") boolean scopeCheckLlmEnabled,
                      @Value("${bot.guardrails.out-of-scope-message:}") String outOfScopeMessage) {
        this.languageModel = languageModel;
        this.scopeCheckLlmEnabled = scopeCheckLlmEnabled;
        this.outOfScopeMessage = outOfScopeMessage != null && !outOfScopeMessage.isBlank()
            ? outOfScopeMessage
            : "Solo puedo ayudarte con información sobre nuestros servicios, horarios, precios y contacto. Para otros temas, escríbenos por teléfono o email.";
    }

    /**
     * Evalúa si el mensaje del usuario está dentro del alcance del asistente.
     * Si no, devuelve resultado con allowed=false y mensaje para mostrar al usuario.
     */
    public ScopeResult check(String userMessage, String tenantId) {
        if (userMessage == null || userMessage.isBlank()) {
            return ScopeResult.allow();
        }
        String normalized = userMessage.strip();

        // 1) Patrones de jailbreak / cambio de rol
        for (Pattern p : JAILBREAK_PATTERNS) {
            if (p.matcher(normalized).find()) {
                log.info("[GUARDRAIL] Entrada bloqueada por patrón (tenant={}): {}", tenantId, p.pattern());
                return ScopeResult.block(outOfScopeMessage);
            }
        }

        // 2) Opcional: clasificación por LLM (in-scope vs out-of-scope)
        if (scopeCheckLlmEnabled && languageModel.isPresent()) {
            if (!isInScopeByLlm(normalized)) {
                log.info("[GUARDRAIL] Entrada marcada fuera de alcance por clasificador LLM (tenant={})", tenantId);
                return ScopeResult.block(outOfScopeMessage);
            }
        }

        return ScopeResult.allow();
    }

    public String getOutOfScopeMessage() {
        return outOfScopeMessage;
    }

    private boolean isInScopeByLlm(String userMessage) {
        try {
            String prompt = "¿Esta pregunta es sobre servicios del negocio, horarios, precios, citas o información de contacto que un asistente al cliente debería responder? Responde únicamente SÍ o NO.\nPregunta: " + userMessage;
            LlmRequest request = new LlmRequest(prompt, List.of("Responde solo SÍ o NO. Sin explicación."), List.of(), 10);
            LlmResponse response = languageModel.get().generate(request);
            if (!response.isSuccess()) return true; // en caso de error, permitir (no bloquear por fallo del clasificador)
            String answer = response.getText() != null ? response.getText().strip().toUpperCase() : "";
            return answer.startsWith("SÍ") || answer.startsWith("SI") || answer.startsWith("YES");
        } catch (Exception e) {
            log.warn("[GUARDRAIL] Error en clasificador LLM, permitiendo mensaje: {}", e.getMessage());
            return true;
        }
    }

    public record ScopeResult(boolean allowed, String blockMessage) {
        public static ScopeResult allow() {
            return new ScopeResult(true, null);
        }
        public static ScopeResult block(String message) {
            return new ScopeResult(false, message);
        }
    }
}
