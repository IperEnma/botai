package com.botai.application.chatbot.orchestration;

import com.botai.application.chatbot.dto.IntentClassification;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.InboundMessage;

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
