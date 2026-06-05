package com.botai.infrastructure.chatbot.ai;

import com.botai.application.chatbot.prompt.BotPrompts;
import com.botai.application.chatbot.service.agenda.PublicAgendaLinkResolver;
import com.botai.infrastructure.security.context.ThreadTenantContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.stereotype.Component;

/**
 * Herramienta para obtener el enlace real de reserva online (Agenda). Evita que el LLM invente URLs externas.
 */
@Component
public class AgendaPublicUrlTools {

    private static final Logger log = LoggerFactory.getLogger(AgendaPublicUrlTools.class);

    private final PublicAgendaLinkResolver publicAgendaLinkResolver;
    private final BotToolCallGuard toolCallGuard;

    public AgendaPublicUrlTools(PublicAgendaLinkResolver publicAgendaLinkResolver,
                                BotToolCallGuard toolCallGuard) {
        this.publicAgendaLinkResolver = publicAgendaLinkResolver;
        this.toolCallGuard = toolCallGuard;
    }

    @Tool(description = BotPrompts.ToolsAgendar.TOOL_OBTENER_ENLACE_AGENDA)
    public String obtenerEnlaceReservaOnline() {
        String blocked = toolCallGuard.gate();
        if (blocked != null) {
            return blocked;
        }
        String tenantId = ThreadTenantContext.getTenantId();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_TENANT_UNKNOWN;
        }
        return publicAgendaLinkResolver.buildBookingReplyForTenant(tenantId)
            .map(msg -> "ENLACE_AGENDA_OK:\n" + msg)
            .orElseGet(() -> {
                log.warn("[AGENDA-URL-TOOL] Sin enlace público tenant={}", tenantId);
                return "SIN_ENLACE_AGENDA: " + publicAgendaLinkResolver.noLinkMessage();
            });
    }
}
