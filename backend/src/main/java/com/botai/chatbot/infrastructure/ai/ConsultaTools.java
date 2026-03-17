package com.botai.chatbot.infrastructure.ai;

import com.botai.chatbot.domain.context.TenantContext;
import com.botai.chatbot.domain.model.KnowledgeChunk;
import com.botai.chatbot.application.service.KnowledgeService;
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

    @Tool(description = "Obtener el horario de atención del negocio. Usar cuando pregunten por horarios, días abiertos, cuándo abren o cierran.")
    public String getHorario() {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return "No se pudo identificar el negocio.";
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
            return "No hay horario configurado.";
        }
        return String.join("\n", daysWithHours);
    }

    @Tool(description = "Listar los servicios que ofrece el negocio. Usar cuando pregunten qué servicios tienen, qué ofrecen, qué hacen.")
    public String listarServicios() {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return "No se pudo identificar el negocio.";
        }
        List<ServiceEntity> services = serviceRepository.findByTenantIdAndActiveTrueOrderBySortOrderAsc(tenantId);
        if (services == null || services.isEmpty()) {
            return "No hay servicios configurados.";
        }
        return services.stream().map(ServiceEntity::getName).collect(Collectors.joining(", "));
    }

    @Tool(description = "Buscar en la base de conocimiento del negocio. Usar cuando pregunten algo que no sea solo horario o lista de servicios: precios, ubicación, qué hacen, información general.")
    public String buscarConocimiento(@ToolParam(description = "Pregunta o tema a buscar") String pregunta) {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return "No se pudo identificar el negocio.";
        }
        if (pregunta == null || pregunta.isBlank()) {
            return "No hay contenido para esa búsqueda.";
        }
        List<KnowledgeChunk> chunks = knowledgeService.findRelevant(pregunta, RAG_MAX_CHUNKS, tenantId);
        if (chunks.isEmpty()) {
            return "No hay información en la base de conocimiento para esa pregunta.";
        }
        return chunks.stream()
            .map(c -> "[" + c.getTopic() + "] " + c.getContent())
            .collect(Collectors.joining("\n\n"));
    }
}
