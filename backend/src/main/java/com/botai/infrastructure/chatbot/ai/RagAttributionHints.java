package com.botai.infrastructure.chatbot.ai;

import com.botai.domain.chatbot.model.KnowledgeChunk;
import com.botai.infrastructure.security.context.ThreadTenantContext;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Frases naturales para el prompt (nunca exponer topics/chunks/tools al usuario final).
 */
public final class RagAttributionHints {

    private RagAttributionHints() {}

    public static String promptInstructionForChunks(List<KnowledgeChunk> chunks) {
        if (chunks == null || chunks.isEmpty()) {
            return "";
        }
        Set<String> phrases = new LinkedHashSet<>();
        for (KnowledgeChunk chunk : chunks) {
            String phrase = phraseForTopic(chunk.getTopic());
            if (phrase != null && !phrase.isBlank()) {
                phrases.add(phrase);
            }
        }
        if (phrases.isEmpty()) {
            return "Puedes anclar la respuesta con frases naturales como «según la información que tenemos» "
                + "o «con los datos publicados del negocio». Nunca menciones bases de datos, fragmentos, herramientas, APIs ni sistemas internos.";
        }
        return "Puedes anclar la respuesta con frases naturales como: "
            + String.join("; ", phrases)
            + ". Nunca menciones bases de datos, fragmentos, herramientas, APIs ni sistemas internos.";
    }

    static String phraseForTopic(String topic) {
        if (topic == null || topic.isBlank()) {
            return null;
        }
        String t = topic.toLowerCase(Locale.ROOT);
        if (t.contains("horario")) {
            return "«según nuestros horarios de atención»";
        }
        if (t.contains("servicio")) {
            return "«según nuestros servicios»";
        }
        if (t.contains("información del negocio") || t.contains("negocio")) {
            return "«según la información del negocio»";
        }
        if (t.contains("precio") || t.contains("tarifa")) {
            return "«según nuestras tarifas publicadas»";
        }
        return "«con la información que tenemos»";
    }
}
