package com.botai.infrastructure.chatbot.config;

import com.botai.application.chatbot.orchestration.ConversationModeOrchestrator;
import com.botai.application.chatbot.service.conversation.common.FaqService;
import com.botai.application.chatbot.service.inbound.ActionDispatcher;
import com.botai.application.chatbot.service.inbound.ChatSessionService;
import com.botai.application.chatbot.service.inbound.ConversationCore;
import com.botai.application.chatbot.service.inbound.MessageHistoryService;
import com.botai.application.chatbot.service.knowledge.KnowledgeService;
import com.botai.application.chatbot.usecase.ProcessInboundMessageUseCase;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.domain.chatbot.repository.FaqRepository;
import com.botai.domain.chatbot.repository.KnowledgeRepository;
import com.botai.domain.chatbot.service.BotAction;
import com.botai.infrastructure.chatbot.ai.AgendarTools;
import com.botai.infrastructure.chatbot.ai.ConsultaTools;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.PromptChatMemoryAdvisor;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.ai.chat.memory.ChatMemoryRepository;
import org.springframework.ai.chat.memory.MessageWindowChatMemory;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.PromptTemplate;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.beans.factory.annotation.Qualifier;
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
     * {@link com.botai.infrastructure.chatbot.ai.memory.JpaChatMemoryRepository} implementa {@link ChatMemoryRepository}.
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

    /**
     * Cliente sin tools ni memoria: segunda pasada de auto-revisión de respuesta ({@code bot.rag.self-review-enabled}).
     */
    @Bean
    @Qualifier("chatClientPlain")
    public ChatClient chatClientPlain(ChatModel chatModel) {
        return ChatClient.builder(chatModel).build();
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
