package com.botai.application.chatbot.orchestration;

import com.botai.application.chatbot.dto.ConversationRouteResult;

import java.util.Optional;

/**
 * Strategy: una implementación por {@link ConversationMode}, implementada por los servicios de aplicación
 * ({@link com.botai.application.chatbot.service.conversation.faq.FaqConversationService},
 * {@link com.botai.application.chatbot.service.conversation.ai.RagLlmChatService},
 * {@link com.botai.application.chatbot.service.conversation.faqai.FaqAndAiConversationService}) — sin capa intermedia.
 */
public interface ConversationModeHandler {

    /** Modo que este manejador atiende (1:1 con la enum). */
    ConversationMode mode();

    Optional<ConversationRouteResult> handle(ConversationHandlingContext ctx);
}
