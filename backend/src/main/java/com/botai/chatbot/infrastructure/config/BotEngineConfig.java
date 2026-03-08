package com.botai.chatbot.infrastructure.config;

import com.botai.chatbot.application.service.*;
import com.botai.chatbot.application.usecase.ProcessInboundMessageUseCase;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import com.botai.chatbot.domain.repository.ConversationRepository;
import com.botai.chatbot.domain.repository.FaqRepository;
import com.botai.chatbot.domain.repository.KnowledgeRepository;
import com.botai.chatbot.domain.service.BotAction;
import com.botai.chatbot.domain.service.LanguageModel;
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
    public HybridAiService hybridAiService(LanguageModel languageModel,
                                           ConversationRepository conversationRepository,
                                           HybridAiService.AiContextBuilder contextBuilder,
                                           HybridAiService.ResponseValidator responseValidator,
                                           MessageHistoryService messageHistoryService) {
        return new HybridAiService(languageModel, conversationRepository, contextBuilder, responseValidator, messageHistoryService);
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
                                     BotReadinessService readinessService) {
        return new IntentRouter(featureFlagService, faqService, hybridAiService, actionDispatcher, menuService, scopeGuard, readinessService);
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
