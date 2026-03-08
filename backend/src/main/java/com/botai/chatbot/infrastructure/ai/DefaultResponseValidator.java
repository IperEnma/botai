package com.botai.chatbot.infrastructure.ai;

import com.botai.chatbot.application.service.HybridAiService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.regex.Pattern;

/**
 * Validates/sanitizes LLM output. Recorta longitud, detecta código o respuestas fuera de rol
 * y las reemplaza por mensaje de alcance para evitar jailbreak por salida.
 */
@Component
public class DefaultResponseValidator implements HybridAiService.ResponseValidator {

    private static final int MAX_LENGTH = 1000;

    /** Respuestas que sugieren código o rol incorrecto se reemplazan por este mensaje */
    private static final Pattern CODE_BLOCK = Pattern.compile("```[\\s\\S]*?```", Pattern.DOTALL);
    private static final Pattern CODE_INDICATORS = Pattern.compile(
        "(?i)(#include\\s*<|int\\s+main\\s*\\(|printf\\s*\\(|return\\s+0\\s*;|def\\s+\\w+\\s*\\(|function\\s+\\w+\\s*\\()"
    );

    private final String outOfScopeFallback;

    /** No se carga mensaje por defecto: debe configurarse en bot.guardrails.out-of-scope-message si se desea. */
    public DefaultResponseValidator(
            @Value("${bot.guardrails.out-of-scope-message:}") String outOfScopeMessage) {
        this.outOfScopeFallback = outOfScopeMessage != null && !outOfScopeMessage.isBlank()
            ? outOfScopeMessage
            : "";
    }

    @Override
    public String validateAndSanitize(String rawResponse) {
        if (rawResponse == null) return "";
        String s = rawResponse.strip();

        // Guardrail de salida: si contiene bloques de código o indicadores de código, no exponer
        if (CODE_BLOCK.matcher(s).find() || CODE_INDICATORS.matcher(s).find()) {
            return outOfScopeFallback;
        }

        if (s.length() > MAX_LENGTH) {
            s = s.substring(0, MAX_LENGTH) + "...";
        }
        return s;
    }
}
