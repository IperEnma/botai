package com.botai.infrastructure.chatbot.ai;

import com.botai.application.chatbot.prompt.BotPrompts;
import com.botai.application.chatbot.service.agenda.PublicAgendaLinkResolver;
import com.botai.application.chatbot.support.InboundTextHeuristics;
import com.botai.application.chatbot.service.conversation.ai.RagLlmChatService;
import com.botai.application.chatbot.service.inbound.ChatSessionService;
import com.botai.application.chatbot.service.inbound.MessageHistoryService;
import com.botai.application.chatbot.service.knowledge.KnowledgeService;
import com.botai.domain.chatbot.model.RagRetrievalResult;
import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.KnowledgeChunk;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * RAG: construye el system prompt con fragmentos devueltos por búsqueda (semántica o keywords).
 */
@Component
@Primary
public class RagAiContextBuilder implements RagLlmChatService.AiContextBuilder {

    private static final Logger log = LoggerFactory.getLogger(RagAiContextBuilder.class);
    private static final int RAG_MAX_CHUNKS = 5;

    private final KnowledgeService knowledgeService;
    private final MessageHistoryService messageHistoryService;
    private final PublicAgendaLinkResolver publicAgendaLinkResolver;
    private final int maxChunks;

    public RagAiContextBuilder(KnowledgeService knowledgeService,
                               MessageHistoryService messageHistoryService,
                               PublicAgendaLinkResolver publicAgendaLinkResolver,
                               @Value("${bot.rag.max-chunks:3}") int maxChunks) {
        this.knowledgeService = knowledgeService;
        this.messageHistoryService = messageHistoryService;
        this.publicAgendaLinkResolver = publicAgendaLinkResolver;
        this.maxChunks = maxChunks > 0 ? maxChunks : RAG_MAX_CHUNKS;
    }

    @Override
    public RagLlmChatService.BuildContextResult buildContext(ConversationState state, String userMessage) {
        String tenantId = state.getContextValue(ConversationContextKeys.TENANT_ID, String.class);

        if (InboundTextHeuristics.looksLikeGreetingOnly(userMessage)) {
            log.info("[RAG] buildContext saludo puro tenantId={} query='{}' -> sin chunks ni BOOKING_URL",
                tenantId, userMessage);
            return RagLlmChatService.BuildContextResult.greetingOnly(
                BotPrompts.RagChat.ragGreetingOnlyPreambleLines());
        }

        String conversationId = state.getConversationId();
        String sessionId = ChatSessionService.sessionIdFrom(state);
        List<String> history = messageHistoryService.getHistory(conversationId, sessionId);
        RagRetrievalResult retrieval = knowledgeService.retrieveForTurn(userMessage, maxChunks, tenantId, history);
        List<KnowledgeChunk> chunks = retrieval.chunks();

        log.info("[RAG] buildContext tenantId={} userQuery='{}' retrievalQueryLen={} chunks={} cragRejected={} topicHints={} avgSim={}",
            tenantId,
            userMessage,
            retrieval.retrievalQuery() != null ? retrieval.retrievalQuery().length() : 0,
            chunks.size(),
            retrieval.cragRejected(),
            retrieval.topicPrefixes(),
            String.format(Locale.ROOT, "%.3f", retrieval.avgSimilarity()));

        List<String> lines = new ArrayList<>(BotPrompts.RagChat.ragInstructionPreambleLines());

        LocalDate today = LocalDate.now();
        Locale es = new Locale("es");
        String dayName = today.getDayOfWeek().getDisplayName(TextStyle.FULL, es);
        LocalDate tomorrow = today.plusDays(1);
        LocalDate dayAfterTomorrow = today.plusDays(2);
        String tomorrowLine = tomorrow.format(DateTimeFormatter.ISO_LOCAL_DATE)
            + " (" + tomorrow.getDayOfWeek().getDisplayName(TextStyle.FULL, es) + ")";
        String dayAfterLine = dayAfterTomorrow.format(DateTimeFormatter.ISO_LOCAL_DATE)
            + " (" + dayAfterTomorrow.getDayOfWeek().getDisplayName(TextStyle.FULL, es) + ")";

        lines.add(BotPrompts.RagChat.CURRENT_DATE_SECTION_TITLE);
        lines.add("HOY (zona horaria del servidor del bot): " + today.format(DateTimeFormatter.ISO_LOCAL_DATE) + " (" + dayName + ").");
        // Mantener líneas cortas y no “explicativas”: el modelo tiende a repetir texto literal al usuario.
        lines.add("MAÑANA: " + tomorrowLine + ".");
        lines.add("PASADO MAÑANA: " + dayAfterLine + ".");
        lines.add(BotPrompts.RagChat.CURRENT_DATE_RULE);
        lines.add("");
        appendOfficialBookingUrl(lines, tenantId);

        if (chunks.isEmpty()) {
            if (retrieval.cragRejected()) {
                log.warn("[RAG] buildContext CRAG rechazó chunks tenantId={} -> solo tools", tenantId);
            } else {
                log.warn("[RAG] buildContext sin chunks tenantId={} query='{}' -> contexto mínimo", tenantId, userMessage);
            }
            return RagLlmChatService.BuildContextResult.noChunks(lines);
        }

        lines.add(BotPrompts.RagChat.FRAGMENTS_SECTION_TITLE);
        for (KnowledgeChunk c : chunks) {
            lines.add("[" + c.getTopic() + "] " + c.getContent());
        }
        lines.add(BotPrompts.RagChat.FRAGMENTS_SECTION_END);
        return RagLlmChatService.BuildContextResult.withChunks(lines);
    }

    private void appendOfficialBookingUrl(List<String> lines, String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return;
        }
        publicAgendaLinkResolver.findPublicUrl(tenantId).ifPresent(url -> {
            lines.add(BotPrompts.RagChat.BOOKING_URL_SECTION_TITLE);
            lines.add(BotPrompts.RagChat.bookingUrlLine(url));
            lines.add(BotPrompts.RagChat.BOOKING_URL_RULE);
            lines.add("");
        });
    }
}
