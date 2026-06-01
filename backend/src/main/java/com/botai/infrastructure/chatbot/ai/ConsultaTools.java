package com.botai.infrastructure.chatbot.ai;

import com.botai.application.chatbot.prompt.BotPrompts;
import com.botai.application.chatbot.service.agenda.AgendaHorarioTextService;
import com.botai.application.chatbot.service.knowledge.KnowledgeService;
import com.botai.infrastructure.security.context.ThreadTenantContext;
import com.botai.domain.chatbot.model.KnowledgeChunk;
import com.botai.infrastructure.agenda.persistence.entity.ServiceEntity;
import com.botai.infrastructure.agenda.persistence.jpa.ServiceJpaRepository;
import com.botai.infrastructure.agenda.support.AgendaPrimaryBusinessResolver;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Tools de solo lectura para la IA: horario, servicios, conocimiento.
 * El modelo puede llamarlas cuando el usuario pregunte; el tenant se toma de {@link ThreadTenantContext}.
 */
@Component
public class ConsultaTools {

    private static final int RAG_MAX_CHUNKS = 5;

    private final AgendaHorarioTextService agendaHorarioTextService;
    private final ServiceJpaRepository agendaServiceRepository;
    private final AgendaPrimaryBusinessResolver primaryBusinessResolver;
    private final KnowledgeService knowledgeService;

    public ConsultaTools(AgendaHorarioTextService agendaHorarioTextService,
                         ServiceJpaRepository agendaServiceRepository,
                         AgendaPrimaryBusinessResolver primaryBusinessResolver,
                         KnowledgeService knowledgeService) {
        this.agendaHorarioTextService = agendaHorarioTextService;
        this.agendaServiceRepository = agendaServiceRepository;
        this.primaryBusinessResolver = primaryBusinessResolver;
        this.knowledgeService = knowledgeService;
    }

    @Tool(description = BotPrompts.ToolsConsulta.TOOL_GET_HORARIO)
    public String getHorario() {
        String tenantId = ThreadTenantContext.getTenantId();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsConsulta.ERR_TENANT_UNKNOWN;
        }
        return agendaHorarioTextService.formatHorarioForTenant(tenantId)
            .orElse(BotPrompts.ToolsConsulta.ERR_NO_HORARIO);
    }

    @Tool(description = BotPrompts.ToolsConsulta.TOOL_LISTAR_SERVICIOS)
    public String listarServicios() {
        String tenantId = ThreadTenantContext.getTenantId();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsConsulta.ERR_TENANT_UNKNOWN;
        }
        var businessId = primaryBusinessResolver.findPrimaryBusinessId(tenantId);
        if (businessId.isEmpty()) {
            return BotPrompts.ToolsConsulta.ERR_NO_SERVICIOS;
        }
        List<ServiceEntity> services = agendaServiceRepository.findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(businessId.get());
        if (services == null || services.isEmpty()) {
            return BotPrompts.ToolsConsulta.ERR_NO_SERVICIOS;
        }
        return services.stream().map(ServiceEntity::getNombre).collect(Collectors.joining(", "));
    }

    @Tool(description = BotPrompts.ToolsConsulta.TOOL_BUSCAR_CONOCIMIENTO)
    public String buscarConocimiento(@ToolParam(description = BotPrompts.ToolsConsulta.PARAM_PREGUNTA) String pregunta) {
        String tenantId = ThreadTenantContext.getTenantId();
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
