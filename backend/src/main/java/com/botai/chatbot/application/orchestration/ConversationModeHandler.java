package com.botai.chatbot.application.orchestration;

import com.botai.chatbot.application.dto.ConversationRouteResult;

import java.util.Optional;

/**
 * Strategy: una implementación por {@link ConversationMode}, implementada por los servicios de aplicación
 * ({@link com.botai.chatbot.application.service.conversation.faq.FaqConversationService},
 * {@link com.botai.chatbot.application.service.conversation.ai.RagLlmChatService},
 * {@link com.botai.chatbot.application.service.conversation.faqai.FaqAndAiConversationService}) — sin capa intermedia.
 */
public interface ConversationModeHandler {

    /** Modo que este manejador atiende (1:1 con la enum). */
    ConversationMode mode();

    Optional<ConversationRouteResult> handle(ConversationHandlingContext ctx);
}
