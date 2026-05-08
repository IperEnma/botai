package com.botai.application.chatbot.service.action;

import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.repository.ConversationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.PreparedStatementSetter;
import org.springframework.jdbc.core.RowMapper;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GetAgendaPublicUrlActionTest {

    @Mock
    private ConversationRepository conversationRepository;
    @Mock
    private JdbcTemplate jdbcTemplate;

    private GetAgendaPublicUrlAction action;

    @BeforeEach
    void setUp() {
        action = new GetAgendaPublicUrlAction(conversationRepository, jdbcTemplate, "http://localhost:5173/");
    }

    @Test
    void findPrimaryPublicSlug_delegatesToJdbc() {
        when(jdbcTemplate.query(anyString(), any(PreparedStatementSetter.class), any(RowMapper.class)))
            .thenReturn(List.of("mi-slug"));

        Optional<String> slug = action.findPrimaryPublicSlug("tenant-1");
        assertThat(slug).contains("mi-slug");
    }

    @Test
    void execute_buildsFrontendHashUrl() {
        when(jdbcTemplate.query(anyString(), any(PreparedStatementSetter.class), any(RowMapper.class)))
            .thenReturn(List.of("clinica-abc"));

        var state = ConversationState.builder()
            .conversationId("c1")
            .context(java.util.Map.of("tenantId", "t1"))
            .build();

        var out = action.execute(state, "link");
        assertThat(out.getText()).contains("http://localhost:5173/#/agenda/clinica-abc");
        verify(conversationRepository).clearIntent("c1");
    }

    @Test
    void execute_noSlug_userFacingMessage() {
        when(jdbcTemplate.query(anyString(), any(PreparedStatementSetter.class), any(RowMapper.class)))
            .thenReturn(Collections.emptyList());

        var state = ConversationState.builder()
            .conversationId("c1")
            .context(java.util.Map.of("tenantId", "t1"))
            .build();

        var out = action.execute(state, "x");
        assertThat(out.getText()).contains("enlace público");
        verify(conversationRepository).clearIntent("c1");
    }
}
