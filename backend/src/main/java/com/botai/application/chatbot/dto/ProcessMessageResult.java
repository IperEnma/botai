package com.botai.application.chatbot.dto;

import com.botai.domain.chatbot.model.OutboundMessage;

/**
 * Result of processing an inbound message (for logging/metrics).
 */
public record ProcessMessageResult(
    OutboundMessage outboundMessage,
    String intentSource,  // "faq" | "ai" | "action" | "fallback"
    String conversationId
) {}
