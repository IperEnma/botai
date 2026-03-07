package com.botai.chatbot.application.dto;

import com.botai.chatbot.domain.model.OutboundMessage;

/**
 * Result of processing an inbound message (for logging/metrics).
 */
public record ProcessMessageResult(
    OutboundMessage outboundMessage,
    String intentSource,  // "faq" | "ai" | "action" | "fallback"
    String conversationId
) {}
