package com.botai.chatbot.infrastructure.channel;

import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.domain.model.OutboundMessage;

/**
 * Contract for channel adapters. Each channel (WhatsApp, Telegram, Web) implements this.
 * - Translates external payload to InboundMessage
 * - Translates OutboundMessage to channel-specific format and sends response
 */
public interface ChannelAdapter {

    /**
     * Unique channel identifier (e.g. "whatsapp", "telegram", "web").
     */
    String getChannelId();

    /**
     * Parse raw payload from the channel into a canonical InboundMessage.
     */
    InboundMessage toInboundMessage(Object rawPayload);

    /**
     * Send the outbound message through this channel.
     * Uses conversationId or stored mapping to know where to send.
     */
    void send(OutboundMessage message);
}
