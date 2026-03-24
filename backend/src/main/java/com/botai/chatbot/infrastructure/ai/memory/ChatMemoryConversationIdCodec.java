package com.botai.chatbot.infrastructure.ai.memory;

/**
 * Codifica {@code conversationId} + {@code sessionId} en un solo id para
 * {@link org.springframework.ai.chat.memory.ChatMemory} (Spring AI espera un string por conversación).
 */
public final class ChatMemoryConversationIdCodec {

    /** Separador improbable en IDs de canal (WhatsApp, etc.). */
    private static final String SEP = "\u001E";

    private ChatMemoryConversationIdCodec() {}

    public static String encode(String conversationId, String sessionId) {
        if (conversationId == null || conversationId.isBlank()) {
            throw new IllegalArgumentException("conversationId required");
        }
        String sess = sessionId != null && !sessionId.isBlank() ? sessionId : "";
        return conversationId + SEP + sess;
    }

    public record Parts(String conversationId, String sessionId) {}

    /**
     * @param key valor devuelto por {@link #encode(String, String)}
     */
    public static Parts decode(String key) {
        if (key == null || key.isBlank()) {
            throw new IllegalArgumentException("memory key required");
        }
        int i = key.indexOf(SEP);
        if (i < 0) {
            return new Parts(key, null);
        }
        String conv = key.substring(0, i);
        String sess = key.substring(i + SEP.length());
        return new Parts(conv, sess.isBlank() ? null : sess);
    }
}
