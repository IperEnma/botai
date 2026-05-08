package com.botai.infrastructure.chatbot.ai;



import com.botai.application.chatbot.prompt.BotPrompts;

import com.botai.application.chatbot.service.conversation.ai.RagLlmChatService;

import com.botai.domain.chatbot.model.ConversationState;

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

