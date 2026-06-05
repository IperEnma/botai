package com.botai.infrastructure.chatbot.ai;

import com.botai.application.chatbot.prompt.BotPrompts;
import com.botai.application.chatbot.service.conversation.ai.RagLlmChatService;
import com.botai.infrastructure.chatbot.config.BotMessages;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.util.regex.Pattern;

/**
 * Validates/sanitizes LLM output. Recorta longitud, detecta código o respuestas fuera de rol
 * y las reemplaza por mensaje de alcance para evitar jailbreak por salida.
 * También convierte salidas erróneas tipo JSON de plantilla WhatsApp ({@code {"name":"respuestaSaludo",...}})
 * en texto plano: el {@link com.botai.infrastructure.chatbot.channel.whatsapp.WhatsAppCloudApiClient} solo envía
 * {@code type: text} con {@code text.body} = ese string; Meta no interpreta ese JSON como plantilla.
 */
@Component
public class DefaultResponseValidator implements RagLlmChatService.ResponseValidator {

    private static final int MAX_LENGTH = 1000;

    private static final ObjectMapper JSON = new ObjectMapper();

    /** Respuestas que sugieren código o rol incorrecto se reemplazan por este mensaje */
    private static final Pattern CODE_BLOCK = Pattern.compile("```[\\s\\S]*?```", Pattern.DOTALL);
    private static final Pattern CODE_INDICATORS = Pattern.compile(
        "(?i)(#include\\s*<|int\\s+main\\s*\\(|printf\\s*\\(|return\\s+0\\s*;|def\\s+\\w+\\s*\\(|function\\s+\\w+\\s*\\()"
    );

    private final BotMessages botMessages;

    public DefaultResponseValidator(BotMessages botMessages) {
        this.botMessages = botMessages;
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

        // Algunos modelos agregan muletillas/apologías irrelevantes al iniciar. Recortar para mantener foco.
        s = s.replaceFirst("(?i)^(disculpa\\s+el\\s+retraso\\.?\\s*)+", "").strip();
        s = s.replaceFirst("(?i)^(disculpa\\.?\\s*)+", "").strip();

        s = stripTypographicQuotes(s);

        s = replaceWhatsappTemplateJsonWithPlainText(s);

        // No hablar como administrador: reemplazar frases de "panel/datos cargados" por voz del negocio
        s = sanitizeAdminLanguage(s);

        // Guardrail de salida: si contiene bloques de código o indicadores de código, no exponer
        if (CODE_BLOCK.matcher(s).find() || CODE_INDICATORS.matcher(s).find()) {
            return botMessages.getGuardrailBlock();
        }

        if (s.length() > MAX_LENGTH) {
            s = s.substring(0, MAX_LENGTH) + "...";
        }
        return s;
    }

    /** Quita comillas tipográficas y recorta comillas ASCII decorativas (mejor legibilidad en WhatsApp). */
    private static String stripTypographicQuotes(String s) {
        if (s == null || s.isEmpty()) {
            return s;
        }
        String t = s.replace('\u201c', ' ').replace('\u201d', ' ')
            .replace('\u2018', ' ').replace('\u2019', ' ')
            .replace('\u00ab', ' ').replace('\u00bb', ' ');
        t = t.replaceAll("\\s{2,}", " ").strip();
        while (t.length() >= 2 && t.startsWith("\"") && t.endsWith("\"")) {
            t = t.substring(1, t.length() - 1).strip();
        }
        return t;
    }

    /**
     * Si el modelo devolvió JSON estilo plantilla Meta (no válido como cuerpo de mensaje de texto), sustituir por texto útil.
     */
    private String replaceWhatsappTemplateJsonWithPlainText(String s) {
        String t = s.strip();
        if (!t.startsWith("{") || !t.contains("\"name\"") || !t.contains("\"parameters\"")) {
            return s;
        }
        try {
            JsonNode root = JSON.readTree(t);
            JsonNode params = root.get("parameters");
            if (params != null && params.isObject()) {
                StringBuilder sb = new StringBuilder();
                params.fields().forEachRemaining(e -> {
                    JsonNode v = e.getValue();
                    if (v != null && v.isTextual()) {
                        String txt = v.asText().strip();
                        if (!txt.isEmpty() && !txt.matches("^[!?.¿¡…\\s-]+$")) {
                            if (sb.length() > 0) {
                                sb.append(' ');
                            }
                            sb.append(txt);
                        }
                    }
                });
                String out = sb.toString().strip();
                if (!out.isBlank()) {
                    return out;
                }
            }
        } catch (Exception e) {
            // seguir con saludo por defecto
        }
        String greeting = botMessages.getGreeting();
        return greeting != null && !greeting.isBlank() ? greeting : BotPrompts.UserFacing.RETRY_LATER;
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
        out = out.replaceAll("(?i)no tienes esa información cargada", BotPrompts.ResponseSanitize.NO_INFO_DISPONIBLE);
        out = out.replaceAll("(?i)no tienes esa información", BotPrompts.ResponseSanitize.NO_INFO_DISPONIBLE);
        out = out.replaceAll("(?i)no tengo otros datos cargados", BotPrompts.ResponseSanitize.NO_MAS_INFO);
        out = out.replaceAll("(?i)\\(?No tenemos otros datos cargados sobre servicios\\.?\\)?", "");
        out = out.replaceAll("(?i)\\(?no tenemos más datos cargados sobre servicios\\.?\\)?", "");
        out = out.replaceAll("(?i)\\.?\\s*\\(?Todos los servicios que tenemos cargados\\.?\\)?", "");
        out = out.replaceAll("(?i)no se ha indicado cómo realizarlo", "");
        out = out.replaceAll("(?i)datos cargados que puedan ayudarte con tu cita", BotPrompts.ResponseSanitize.INFO_CITAS);
        // Evitar “llamá para agendar”: la reserva nueva es por enlace web
        out = out.replaceAll("(?i)por favor,? llam(a|e|en|as) a nuestro número de teléfono[^.]*\\.?", BotPrompts.ResponseSanitize.AGENDAR_EN_CHAT);
        out = out.replaceAll("(?i)llam(a|e|en|as) a nuestro (número de )?teléfono o envía[^.]*\\.?", BotPrompts.ResponseSanitize.AGENDAR_EN_CHAT_CORTO);
        // Limpiar espacios dobles o frases vacías entre paréntesis
        out = out.replaceAll("\\s*\\(\\s*\\)\\s*", "").replaceAll("\\s{2,}", " ").strip();
        return out;
    }
}
