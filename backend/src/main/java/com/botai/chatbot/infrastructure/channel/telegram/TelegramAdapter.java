package com.botai.chatbot.infrastructure.channel.telegram;

import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.domain.model.OutboundMessage;
import com.botai.chatbot.infrastructure.channel.ChannelAdapter;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Telegram channel adapter. Translates Telegram update (webhook) to InboundMessage
 * and OutboundMessage to Telegram sendMessage format.
 */
@Component
public class TelegramAdapter implements ChannelAdapter {

    public static final String CHANNEL_ID = "telegram";

    @Override
    public String getChannelId() {
        return CHANNEL_ID;
    }

    /**
     * Expects Telegram update map: { "message": { "chat": { "id": 123 }, "from": { "id": 456 }, "text": "hello" } }
     */
    @Override
    @SuppressWarnings("unchecked")
    public InboundMessage toInboundMessage(Object rawPayload) {
        if (!(rawPayload instanceof Map)) {
            return InboundMessage.builder()
                .channelId(CHANNEL_ID)
                .userId("unknown")
                .conversationId("unknown")
                .text("")
                .build();
        }
        Map<String, Object> update = (Map<String, Object>) rawPayload;
        Map<String, Object> metadata = Map.of("raw", update);

        Object msgObj = update.get("message");
        String userId = "unknown";
        String chatId = "unknown";
        String text = "";

        if (msgObj instanceof Map) {
            Map<String, Object> msg = (Map<String, Object>) msgObj;
            text = String.valueOf(msg.getOrDefault("text", ""));
            Object from = msg.get("from");
            if (from instanceof Map) {
                Object id = ((Map<?, ?>) from).get("id");
                userId = id != null ? String.valueOf(id) : userId;
            }
            Object chat = msg.get("chat");
            if (chat instanceof Map) {
                Object id = ((Map<?, ?>) chat).get("id");
                chatId = id != null ? String.valueOf(id) : chatId;
            }
        }

        String conversationId = chatId + "@" + CHANNEL_ID;
        return InboundMessage.builder()
            .channelId(CHANNEL_ID)
            .userId(userId)
            .conversationId(conversationId)
            .text(text)
            .metadata(metadata)
            .build();
    }

    @Override
    public void send(OutboundMessage message) {
        // In production: call Telegram Bot API sendMessage(chat_id, text).
        // chat_id can be derived from message.getConversationId() (part before "@telegram").
        // Placeholder; integrate with Telegram Bot API.
        // telegramClient.sendMessage(chatId, message.getText());
    }
}
