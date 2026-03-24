package com.botai.chatbot.infrastructure.config;

import com.botai.chatbot.application.orchestration.ConversationModeOrchestrator;
import com.botai.chatbot.application.service.conversation.common.FaqService;
import com.botai.chatbot.application.service.inbound.ActionDispatcher;
import com.botai.chatbot.application.service.inbound.ChatSessionService;
import com.botai.chatbot.application.service.inbound.ConversationCore;
import com.botai.chatbot.application.service.inbound.MessageHistoryService;
import com.botai.chatbot.application.service.knowledge.KnowledgeService;
import com.botai.chatbot.application.usecase.ProcessInboundMessageUseCase;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import com.botai.chatbot.domain.repository.ConversationRepository;
import com.botai.chatbot.domain.repository.FaqRepository;
import com.botai.chatbot.domain.repository.KnowledgeRepository;
import com.botai.chatbot.domain.service.BotAction;
import com.botai.chatbot.infrastructure.ai.AgendarTools;
import com.botai.chatbot.infrastructure.ai.ConsultaTools;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.PromptChatMemoryAdvisor;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.ai.chat.memory.ChatMemoryRepository;
import org.springframework.ai.chat.memory.MessageWindowChatMemory;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.PromptTemplate;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.beans.factory.annotation.Value;
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
                                             Optional<EmbeddingModel> embeddingModel,
                                             @Value("${bot.rag.min-similarity:0}") double minSimilarity) {
        return new KnowledgeService(knowledgeRepository, embeddingModel.orElse(null), minSimilarity);
    }

    /**
     * {@link com.botai.chatbot.infrastructure.ai.memory.JpaChatMemoryRepository} implementa {@link ChatMemoryRepository}.
     * Ventana alineada con {@code bot.memory.max-history-turns} (cada turno ≈ user + assistant).
     */
    @Bean
    public ChatMemory chatMemory(ChatMemoryRepository chatMemoryRepository,
                                 @Value("${bot.memory.max-history-turns:10}") int maxHistoryTurns) {
        int cap = Math.max(2, maxHistoryTurns * 2);
        return MessageWindowChatMemory.builder()
            .chatMemoryRepository(chatMemoryRepository)
            .maxMessages(cap)
            .build();
    }

    /**
     * Memoria Spring AI: incrusta turnos previos en el system (no altera el orden user/assistant del modelo).
     * Texto en español para alinear con el resto del bot.
     */
    @Bean
    public PromptChatMemoryAdvisor promptChatMemoryAdvisor(ChatMemory chatMemory) {
        PromptTemplate tpl = new PromptTemplate("""
            {instructions}

            Usa la sección MEMORY para mantener coherencia con turnos previos (nombres, fechas, citas acordadas). \
            Prioriza herramientas y datos verificables sobre suposiciones.

            ---------------------
            MEMORY:
            {memory}
            ---------------------
            """);
        return PromptChatMemoryAdvisor.builder(chatMemory)
            .systemPromptTemplate(tpl)
            .build();
    }

    @Bean
    public ChatClient chatClientWithTools(ChatModel chatModel,
                                          AgendarTools agendarTools,
                                          ConsultaTools consultaTools,
                                          PromptChatMemoryAdvisor promptChatMemoryAdvisor) {
        return ChatClient.builder(chatModel)
            .defaultTools(agendarTools, consultaTools)
            .defaultAdvisors(promptChatMemoryAdvisor)
            .build();
    }

    @Bean
    public ActionDispatcher actionDispatcher(List<BotAction> actions,
                                             ConversationRepository conversationRepository) {
        return new ActionDispatcher(actions, conversationRepository);
    }

    @Bean
    public ConversationCore conversationCore(ConversationRepository conversationRepository,
                                              ConversationModeOrchestrator conversationModeOrchestrator,
                                              MessageHistoryService messageHistoryService,
                                              ChatSessionService chatSessionService) {
        return new ConversationCore(conversationRepository, conversationModeOrchestrator, messageHistoryService, chatSessionService);
    }

    @Bean
    public ProcessInboundMessageUseCase processInboundMessageUseCase(ConversationCore conversationCore) {
        return new ProcessInboundMessageUseCase(conversationCore);
    }
}
