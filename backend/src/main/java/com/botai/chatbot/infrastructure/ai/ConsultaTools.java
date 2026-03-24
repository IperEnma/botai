package com.botai.chatbot.infrastructure.ai;

import com.botai.chatbot.application.prompt.BotPrompts;
import com.botai.chatbot.application.service.knowledge.KnowledgeService;
import com.botai.chatbot.domain.context.TenantContext;
import com.botai.chatbot.domain.model.KnowledgeChunk;
import com.botai.chatbot.infrastructure.persistence.entity.BusinessHoursEntity;
import com.botai.chatbot.infrastructure.persistence.entity.ServiceEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.BusinessHoursJpaRepository;
import com.botai.chatbot.infrastructure.persistence.jpa.ServiceJpaRepository;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Tools de solo lectura para la IA: horario, servicios, conocimiento.
 * El modelo puede llamarlas cuando el usuario pregunte; el tenant se toma de TenantContext.
 */
@Component
public class ConsultaTools {

    private static final String[] DAY_NAMES_ES = {"Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"};
    private static final int RAG_MAX_CHUNKS = 5;

    private final BusinessHoursJpaRepository businessHoursRepository;
    private final ServiceJpaRepository serviceRepository;
    private final KnowledgeService knowledgeService;

    public ConsultaTools(BusinessHoursJpaRepository businessHoursRepository,
                         ServiceJpaRepository serviceRepository,
                         KnowledgeService knowledgeService) {
        this.businessHoursRepository = businessHoursRepository;
        this.serviceRepository = serviceRepository;
        this.knowledgeService = knowledgeService;
    }

    @Tool(description = BotPrompts.ToolsConsulta.TOOL_GET_HORARIO)
    public String getHorario() {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsConsulta.ERR_TENANT_UNKNOWN;
        }
        List<BusinessHoursEntity> hours = businessHoursRepository.findByTenantIdOrderByDayOfWeek(tenantId);
        List<String> daysWithHours = new ArrayList<>();
        for (BusinessHoursEntity h : hours) {
            String open = h.getOpenTime();
            String close = h.getCloseTime();
            boolean hasHours = (open != null && !open.isBlank()) || (close != null && !close.isBlank());
            if (hasHours) {
                int day = h.getDayOfWeek();
                String dayLabel = day >= 1 && day <= 7 ? DAY_NAMES_ES[day - 1] : "Día " + day;
                String slot = (open != null ? open : "?") + " - " + (close != null ? close : "?");
                daysWithHours.add(dayLabel + ": " + slot);
            }
        }
        if (daysWithHours.isEmpty()) {
            return BotPrompts.ToolsConsulta.ERR_NO_HORARIO;
        }
        return String.join("\n", daysWithHours);
    }

    @Tool(description = BotPrompts.ToolsConsulta.TOOL_LISTAR_SERVICIOS)
    public String listarServicios() {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsConsulta.ERR_TENANT_UNKNOWN;
        }
        List<ServiceEntity> services = serviceRepository.findByTenantIdAndActiveTrueOrderBySortOrderAsc(tenantId);
        if (services == null || services.isEmpty()) {
            return BotPrompts.ToolsConsulta.ERR_NO_SERVICIOS;
        }
        return services.stream().map(ServiceEntity::getName).collect(Collectors.joining(", "));
    }

    @Tool(description = BotPrompts.ToolsConsulta.TOOL_BUSCAR_CONOCIMIENTO)
    public String buscarConocimiento(@ToolParam(description = BotPrompts.ToolsConsulta.PARAM_PREGUNTA) String pregunta) {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsConsulta.ERR_TENANT_UNKNOWN;
        }
        if (pregunta == null || pregunta.isBlank()) {
            return BotPrompts.ToolsConsulta.ERR_BUSQUEDA_VACIA;
        }
        List<KnowledgeChunk> chunks = knowledgeService.findRelevant(pregunta, RAG_MAX_CHUNKS, tenantId);
        if (chunks.isEmpty()) {
            return BotPrompts.ToolsConsulta.ERR_SIN_RESULTADOS_RAG;
        }
        return chunks.stream()
            .map(c -> "[" + c.getTopic() + "] " + c.getContent())
            .collect(Collectors.joining("\n\n"));
    }
}
