package com.botai.chatbot.infrastructure.config;

import com.botai.chatbot.application.service.*;
import com.botai.chatbot.application.usecase.ProcessInboundMessageUseCase;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import com.botai.chatbot.domain.repository.ConversationRepository;
import com.botai.chatbot.domain.repository.FaqRepository;
import com.botai.chatbot.domain.repository.KnowledgeRepository;
import com.botai.chatbot.domain.service.BotAction;
import com.botai.chatbot.application.service.HybridAiService;
import com.botai.chatbot.infrastructure.config.BotMessages;
import com.botai.chatbot.infrastructure.ai.AgendarTools;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;
import java.util.Optional;

/**
 * Wires application and domain services (composition root). Adapters and persistence are auto-discovered.
 */
@Configuration
public class BotEngineConfig {

    @Bean
    public FaqService faqService(FaqRepository faqRepository) {
        return new FaqService(faqRepository);
    }

    @Bean
    public KnowledgeService knowledgeService(KnowledgeRepository knowledgeRepository,
                                             Optional<EmbeddingModel> embeddingModel) {
        return new KnowledgeService(knowledgeRepository, embeddingModel.orElse(null));
    }

    @Bean
    public ChatClient chatClientWithTools(ChatModel chatModel, AgendarTools agendarTools) {
        return ChatClient.builder(chatModel)
            .defaultTools(agendarTools)
            .build();
    }

    @Bean
    public HybridAiService hybridAiService(ChatModel chatModel,
                                           ChatClient chatClientWithTools,
                                           HybridAiService.AiContextBuilder aiContextBuilder,
                                           HybridAiService.ResponseValidator responseValidator,
                                           MessageHistoryService messageHistoryService,
                                           BotMessages botMessages) {
        return new HybridAiService(chatModel, chatClientWithTools, aiContextBuilder, responseValidator, messageHistoryService,
            botMessages.getTenantUnknown(), botMessages.getNoRagInfo(), botMessages.getAiError());
    }

    @Bean
    public ActionDispatcher actionDispatcher(List<BotAction> actions,
                                             ConversationRepository conversationRepository) {
        return new ActionDispatcher(actions, conversationRepository);
    }

    @Bean
    public IntentRouter intentRouter(FeatureFlagService featureFlagService,
                                     FaqService faqService,
                                     HybridAiService hybridAiService,
                                     ActionDispatcher actionDispatcher,
                                     MenuService menuService,
                                     ScopeGuard scopeGuard,
                                     BotReadinessService readinessService,
                                     IntentClassifierService intentClassifierService,
                                     BotMessages botMessages) {
        return new IntentRouter(featureFlagService, faqService, hybridAiService, actionDispatcher, menuService, scopeGuard, readinessService, intentClassifierService, botMessages);
    }

    @Bean
    public ConversationCore conversationCore(ConversationRepository conversationRepository,
                                              IntentRouter intentRouter,
                                              MessageHistoryService messageHistoryService) {
        return new ConversationCore(conversationRepository, intentRouter, messageHistoryService);
    }

    @Bean
    public ProcessInboundMessageUseCase processInboundMessageUseCase(ConversationCore conversationCore) {
        return new ProcessInboundMessageUseCase(conversationCore);
    }
}
