package com.botai.chatbot.infrastructure.ai;

import com.botai.chatbot.application.prompt.BotPrompts;
import com.botai.chatbot.application.service.conversation.ai.RagLlmChatService;
import com.botai.chatbot.application.service.conversation.common.ConversationActionRouting;
import com.botai.chatbot.application.service.knowledge.KnowledgeService;
import com.botai.chatbot.domain.ConversationContextKeys;
import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.KnowledgeChunk;
import com.botai.chatbot.infrastructure.persistence.entity.ServiceEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.ServiceJpaRepository;
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
import java.util.stream.Collectors;

/**
 * RAG: construye el system prompt solo con fragmentos devueltos por búsqueda (semántica o keywords).
 * En flujo {@code book_appointment} se inyecta además el catálogo real de servicios (BD), antes de los fragmentos RAG.
 */
@Component
@Primary
public class RagAiContextBuilder implements RagLlmChatService.AiContextBuilder {

    private static final Logger log = LoggerFactory.getLogger(RagAiContextBuilder.class);
    private static final int RAG_MAX_CHUNKS = 5;

    private final KnowledgeService knowledgeService;
    private final ServiceJpaRepository serviceJpaRepository;
    private final int maxChunks;

    public RagAiContextBuilder(KnowledgeService knowledgeService,
                               ServiceJpaRepository serviceJpaRepository,
                               @Value("${bot.rag.max-chunks:3}") int maxChunks) {
        this.knowledgeService = knowledgeService;
        this.serviceJpaRepository = serviceJpaRepository;
        this.maxChunks = maxChunks > 0 ? maxChunks : RAG_MAX_CHUNKS;
    }

    @Override
    public RagLlmChatService.BuildContextResult buildContext(ConversationState state, String userMessage) {
        String tenantId = state.getContextValue(ConversationContextKeys.TENANT_ID, String.class);
        List<KnowledgeChunk> chunks = knowledgeService.findRelevant(userMessage, maxChunks, tenantId);

        log.info("[RAG] buildContext tenantId={} query='{}' chunks={} topics={}",
            tenantId,
            userMessage,
            chunks.size(),
            chunks.stream().map(KnowledgeChunk::getTopic).toList());

        boolean bookingFlow = state.hasIntent()
            && ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(state.getCurrentIntent());
        List<String> lines = new ArrayList<>(
            bookingFlow
                ? BotPrompts.RagChat.ragInstructionPreambleLinesForBookingFlow()
                : BotPrompts.RagChat.ragInstructionPreambleLines());

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
        lines.add("MAÑANA: " + tomorrowLine + " — si el usuario dice «mañana», la fecha ISO para tools es la de esta línea, NO la de HOY.");
        lines.add("PASADO MAÑANA: " + dayAfterLine + ".");
        lines.add(BotPrompts.RagChat.CURRENT_DATE_RULE);
        lines.add("");

        if (bookingFlow && tenantId != null && !tenantId.isBlank()) {
            appendOfficialServiceCatalog(lines, tenantId);
        }

        if (chunks.isEmpty()) {
            log.warn("[RAG] buildContext sin chunks para tenantId={} query='{}' -> contexto mínimo (solo reglas + fecha)", tenantId, userMessage);
            return RagLlmChatService.BuildContextResult.noChunks(lines);
        }

        lines.add(BotPrompts.RagChat.FRAGMENTS_SECTION_TITLE);
        for (KnowledgeChunk c : chunks) {
            lines.add("[" + c.getTopic() + "] " + c.getContent());
        }
        lines.add(BotPrompts.RagChat.FRAGMENTS_SECTION_END);
        return RagLlmChatService.BuildContextResult.withChunks(lines);
    }

    private void appendOfficialServiceCatalog(List<String> lines, String tenantId) {
        lines.add(BotPrompts.RagChat.OFFICIAL_SERVICE_CATALOG_TITLE);
        lines.add(BotPrompts.RagChat.OFFICIAL_SERVICE_CATALOG_RULES);
        List<ServiceEntity> services = serviceJpaRepository.findByTenantIdAndActiveTrueOrderBySortOrderAsc(tenantId);
        if (services == null || services.isEmpty()) {
            lines.add("(Sin servicios activos en catálogo para este negocio.)");
        } else {
            String joined = services.stream().map(ServiceEntity::getName).collect(Collectors.joining(", "));
            lines.add("Servicios agendables: " + joined);
        }
        lines.add("");
        log.info("[RAG] Catálogo oficial inyectado (booking) tenantId={} servicios={}",
            tenantId, services == null ? 0 : services.size());
    }
}
