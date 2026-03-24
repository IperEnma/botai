package com.botai.chatbot.infrastructure.ai;



import com.botai.chatbot.application.prompt.BotPrompts;

import com.botai.chatbot.application.service.conversation.ai.RagLlmChatService;

import com.botai.chatbot.domain.model.ConversationState;

import org.springframework.stereotype.Component;



import java.util.ArrayList;
import java.util.List;



/**

 * Builds system prompt for the LLM (sin RAG). Usado si no se usa RagAiContextBuilder.

 */

@Component("defaultAiContextBuilder")
public class DefaultAiContextBuilder implements RagLlmChatService.AiContextBuilder {



    @Override
    public RagLlmChatService.BuildContextResult buildContext(ConversationState state, String userMessage) {
        List<String> lines = BotPrompts.RagChat.minimalNonRagInstructionLines();
        return RagLlmChatService.BuildContextResult.noChunks(new ArrayList<>(lines));
    }

}

