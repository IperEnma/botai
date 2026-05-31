package com.botai.application.chatbot.service.action;

import com.botai.application.chatbot.service.agenda.PublicAgendaLinkResolver;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.repository.ConversationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GetAgendaPublicUrlActionTest {

    @Mock
    private ConversationRepository conversationRepository;
    @Mock
    private PublicAgendaLinkResolver publicAgendaLinkResolver;

    private GetAgendaPublicUrlAction action;

    @BeforeEach
    void setUp() {
        action = new GetAgendaPublicUrlAction(conversationRepository, publicAgendaLinkResolver);
    }

    @Test
    void execute_returnsBookingReplyWithUrl() {
        when(publicAgendaLinkResolver.buildBookingReplyForTenant("t1"))
            .thenReturn(Optional.of("¡Genial! http://localhost:5173/#/reservar/slug"));

        var state = ConversationState.builder()
            .conversationId("c1")
            .context(java.util.Map.of("tenantId", "t1"))
            .build();

        var out = action.execute(state, "link");
        assertThat(out.getText()).contains("/#/reservar/slug");
        verify(conversationRepository).clearIntent("c1");
    }

    @Test
    void execute_noLink_userFacingMessage() {
        when(publicAgendaLinkResolver.buildBookingReplyForTenant("t1")).thenReturn(Optional.empty());
        when(publicAgendaLinkResolver.noLinkMessage()).thenReturn("Sin enlace");

        var state = ConversationState.builder()
            .conversationId("c1")
            .context(java.util.Map.of("tenantId", "t1"))
            .build();

        var out = action.execute(state, "x");
        assertThat(out.getText()).isEqualTo("Sin enlace");
        verify(conversationRepository).clearIntent("c1");
    }
}
