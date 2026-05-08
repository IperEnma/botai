package com.botai.application.chatbot.dto;

import com.botai.domain.chatbot.model.ConversationState;

/**
 * Entrada para {@link com.botai.application.chatbot.service.conversation.faq.FaqConversationService}
 * (menú vía {@link com.botai.application.chatbot.service.conversation.common.MenuNavigationService}).
 *
 * @param aiCompanionEnabled si es false y el usuario está en menú sin match, se re-muestra el menú;
 *                           si es true (modo FAQ+IA), ese fallback lo hace la IA.
 */
public record FaqResolutionRequest(
    String conversationId,
    String tenantId,
    String text,
    ConversationState state,
    boolean aiCompanionEnabled
) {}
