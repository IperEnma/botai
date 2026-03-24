package com.botai.chatbot.application.orchestration;

import com.botai.chatbot.application.dto.IntentClassification;
import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.InboundMessage;

/**
 * Datos que el orquestador construye y pasa al {@link ConversationModeHandler} elegido (clasificación ya resuelta).
 */
public record ConversationHandlingContext(
    String conversationId,
    String tenantId,
    String text,
    InboundMessage inbound,
    ConversationState state,
    IntentClassification classification
) {}
