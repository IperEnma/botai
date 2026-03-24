package com.botai.chatbot.application.dto;

import com.botai.chatbot.domain.model.ConversationState;

/**
 * Entrada para {@link com.botai.chatbot.application.service.conversation.faq.FaqConversationService}
 * (menú vía {@link com.botai.chatbot.application.service.conversation.common.MenuNavigationService}).
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
