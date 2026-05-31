package com.botai.application.chatbot.service.action;

import com.botai.application.chatbot.service.agenda.PublicAgendaLinkResolver;
import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.domain.chatbot.service.BotAction;
import org.springframework.stereotype.Component;

/**
 * Devuelve el vínculo público de agenda (frontend /#/reservar/...) para autogestión del cliente.
 */
@Component
public class GetAgendaPublicUrlAction implements BotAction {

    public static final String ACTION_ID = "get_agenda_public_url";

    private final ConversationRepository conversationRepository;
    private final PublicAgendaLinkResolver publicAgendaLinkResolver;

    public GetAgendaPublicUrlAction(ConversationRepository conversationRepository,
                                    PublicAgendaLinkResolver publicAgendaLinkResolver) {
        this.conversationRepository = conversationRepository;
        this.publicAgendaLinkResolver = publicAgendaLinkResolver;
    }

    @Override
    public String getActionId() {
        return ACTION_ID;
    }

    @Override
    public String getTriggerIntent() {
        return null;
    }

    @Override
    public OutboundMessage execute(ConversationState state, String userInput) {
        String tenantId = state.getContextValue(ConversationContextKeys.TENANT_ID, String.class);
        if (tenantId == null || tenantId.isBlank()) {
            return OutboundMessage.builder()
                .text("No se pudo identificar el negocio.")
                .conversationId(state.getConversationId())
                .tenantId("")
                .build();
        }
        conversationRepository.clearIntent(state.getConversationId());

        String text = publicAgendaLinkResolver.buildBookingReplyForTenant(tenantId)
            .orElse(publicAgendaLinkResolver.noLinkMessage());
        return OutboundMessage.builder()
            .text(text)
            .conversationId(state.getConversationId())
            .tenantId(tenantId)
            .build();
    }
}
