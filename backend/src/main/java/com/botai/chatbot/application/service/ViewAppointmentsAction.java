package com.botai.chatbot.application.service;

import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.OutboundMessage;
import com.botai.chatbot.domain.repository.ConversationRepository;
import com.botai.chatbot.infrastructure.persistence.entity.AppointmentEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.AppointmentJpaRepository;
import com.botai.chatbot.domain.service.BotAction;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Lista las citas del usuario (por userId). Acción "Ver mis citas".
 */
@Component
public class ViewAppointmentsAction implements BotAction {

    private static final String ACTION_ID = "view_appointments";

    private final ConversationRepository conversationRepository;
    private final AppointmentJpaRepository appointmentRepository;

    public ViewAppointmentsAction(ConversationRepository conversationRepository,
                                  AppointmentJpaRepository appointmentRepository) {
        this.conversationRepository = conversationRepository;
        this.appointmentRepository = appointmentRepository;
    }

    @Override
    public String getActionId() {
        return ACTION_ID;
    }

    @Override
    public OutboundMessage execute(ConversationState state, String userInput) {
        String tenantId = state.getContextValue("tenantId", String.class);
        if (tenantId == null || tenantId.isBlank()) {
            return OutboundMessage.builder()
                .text("No se pudo identificar el negocio.")
                .conversationId(state.getConversationId())
                .tenantId("")
                .build();
        }
        String userId = state.getUserId();
        List<AppointmentEntity> list = appointmentRepository.findByTenantIdAndUserIdOrderByAppointmentDateAscAppointmentTimeAsc(tenantId, userId != null ? userId : "");
        conversationRepository.clearIntent(state.getConversationId());

        if (list.isEmpty()) {
            return OutboundMessage.builder()
                .text("No tienes citas agendadas.")
                .conversationId(state.getConversationId())
                .tenantId(tenantId)
                .build();
        }
        StringBuilder sb = new StringBuilder("📅 Tus citas:\n\n");
        for (AppointmentEntity a : list) {
            if (!"scheduled".equals(a.getStatus())) continue;
            sb.append("• ").append(a.getAppointmentDate()).append(" a las ").append(a.getAppointmentTime())
                .append(" - ").append(a.getServiceName())
                .append(" (").append(a.getCustomerName()).append(")\n");
        }
        return OutboundMessage.builder()
            .text(sb.toString().trim())
            .conversationId(state.getConversationId())
            .tenantId(tenantId)
            .build();
    }
}
