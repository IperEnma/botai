package com.botai.application.chatbot.service.action;

import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.infrastructure.config.AppUrlProperties;
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
        AppUrlProperties appUrls = new AppUrlProperties();
        appUrls.setFrontend("http://localhost:5173/");
        action = new GetAgendaPublicUrlAction(conversationRepository, jdbcTemplate, appUrls);
    }

    @Test
    void findPrimaryPublicLink_delegatesToJdbc() {
        when(jdbcTemplate.query(anyString(), any(PreparedStatementSetter.class), any(RowMapper.class)))
            .thenReturn(List.of(new GetAgendaPublicUrlAction.PublicLinkRow(
                    "mi-slug", "micompany", "Mi Negocio", 1L)));

        Optional<GetAgendaPublicUrlAction.PublicLinkRow> link = action.findPrimaryPublicLink("tenant-1");
        assertThat(link).isPresent();
        assertThat(link.get().publicSlug()).isEqualTo("mi-slug");
    }

    @Test
    void execute_buildsReservarUrlForSingleBranch() {
        when(jdbcTemplate.query(anyString(), any(PreparedStatementSetter.class), any(RowMapper.class)))
            .thenReturn(List.of(new GetAgendaPublicUrlAction.PublicLinkRow(
                    "clinica-abc", "clinica", "Clínica", 1L)));

        var state = ConversationState.builder()
            .conversationId("c1")
            .context(java.util.Map.of("tenantId", "t1"))
            .build();

        var out = action.execute(state, "link");
        assertThat(out.getText()).contains("http://localhost:5173/#/reservar/clinica-abc");
        verify(conversationRepository).clearIntent("c1");
    }

    @Test
    void execute_buildsCompanyUrlForMultipleBranches() {
        when(jdbcTemplate.query(anyString(), any(PreparedStatementSetter.class), any(RowMapper.class)))
            .thenReturn(List.of(new GetAgendaPublicUrlAction.PublicLinkRow(
                    "sucursal-1", "felitobarber", "Felito", 2L)));

        var state = ConversationState.builder()
            .conversationId("c1")
            .context(java.util.Map.of("tenantId", "t1"))
            .build();

        var out = action.execute(state, "link");
        assertThat(out.getText()).contains("http://localhost:5173/#/reservar?company=felitobarber");
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
