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
        // Quitar prefijos que algunos modelos devuelven (ej. ": ", ": : ", "Assistant: ")
        s = s.replaceFirst("^[:\\s]+", "").strip();
        if (s.toLowerCase().startsWith("assistant:")) {
            s = s.substring("assistant:".length()).strip();
        }

        // No hablar como administrador: reemplazar frases de "panel/datos cargados" por voz del negocio
        s = sanitizeAdminLanguage(s);

        // Guardrail de salida: si contiene bloques de código o indicadores de código, no exponer
        if (CODE_BLOCK.matcher(s).find() || CODE_INDICATORS.matcher(s).find()) {
            return outOfScopeFallback;
        }

        if (s.length() > MAX_LENGTH) {
            s = s.substring(0, MAX_LENGTH) + "...";
        }
        return s;
    }

    /**
     * Evita que llegue al cliente lenguaje de administrador (panel, datos cargados, etc.).
     * Reemplaza por formulaciones en voz del negocio.
     */
    private static String sanitizeAdminLanguage(String s) {
        if (s == null || s.isBlank()) return s;
        String out = s;
        // "(Todos los servicios que tenemos cargados en el panel.)" -> quitar o reemplazar
        out = out.replaceAll("(?i)\\(?Todos los servicios que tenemos cargados en el panel\\.?\\)?", "");
        out = out.replaceAll("(?i)\\(?cargados en el panel\\.?\\)?", "");
        out = out.replaceAll("(?i)en el panel", "");
        // "no tienes esa información cargada" -> voz negocio
        out = out.replaceAll("(?i)no tienes esa información cargada", "no tenemos esa información disponible");
        out = out.replaceAll("(?i)no tienes esa información", "no tenemos esa información disponible");
        out = out.replaceAll("(?i)no tengo otros datos cargados", "no tenemos más información disponible");
        out = out.replaceAll("(?i)\\(?No tenemos otros datos cargados sobre servicios\\.?\\)?", "");
        out = out.replaceAll("(?i)\\(?no tenemos más datos cargados sobre servicios\\.?\\)?", "");
        out = out.replaceAll("(?i)\\.?\\s*\\(?Todos los servicios que tenemos cargados\\.?\\)?", "");
        out = out.replaceAll("(?i)no se ha indicado cómo realizarlo", "");
        out = out.replaceAll("(?i)datos cargados que puedan ayudarte con tu cita", "información sobre citas");
        // No sugerir llamar para agendar: las citas se hacen por este chat
        out = out.replaceAll("(?i)por favor,? llam(a|e|en|as) a nuestro número de teléfono[^.]*\\.?", "Puedes agendar aquí mismo en el chat; te guiamos paso a paso.");
        out = out.replaceAll("(?i)llam(a|e|en|as) a nuestro (número de )?teléfono o envía[^.]*\\.?", "Puedes agendar aquí en el chat; te guiamos paso a paso.");
        // Limpiar espacios dobles o frases vacías entre paréntesis
        out = out.replaceAll("\\s*\\(\\s*\\)\\s*", "").replaceAll("\\s{2,}", " ").strip();
        return out;
    }
}
