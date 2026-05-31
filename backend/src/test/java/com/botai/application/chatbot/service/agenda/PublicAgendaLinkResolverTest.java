package com.botai.application.chatbot.service.agenda;

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
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PublicAgendaLinkResolverTest {

    @Mock
    private JdbcTemplate jdbcTemplate;

    private PublicAgendaLinkResolver resolver;

    @BeforeEach
    void setUp() {
        AppUrlProperties appUrls = new AppUrlProperties();
        appUrls.setFrontend("http://localhost:5173/");
        resolver = new PublicAgendaLinkResolver(jdbcTemplate, appUrls);
    }

    @Test
    void findPublicUrl_singleBranch() {
        when(jdbcTemplate.query(anyString(), any(PreparedStatementSetter.class), any(RowMapper.class)))
            .thenReturn(List.of(new PublicAgendaLinkResolver.PublicLinkRow(
                "clinica-abc", "clinica", "Clínica", 1L)));

        Optional<String> url = resolver.findPublicUrl("t1");
        assertThat(url).contains("http://localhost:5173/#/reservar/clinica-abc");
    }

    @Test
    void findPublicUrl_multiBranchUsesCompany() {
        when(jdbcTemplate.query(anyString(), any(PreparedStatementSetter.class), any(RowMapper.class)))
            .thenReturn(List.of(new PublicAgendaLinkResolver.PublicLinkRow(
                "sucursal-1", "felitobarber", "Felito", 2L)));

        Optional<String> url = resolver.findPublicUrl("t1");
        assertThat(url).contains("http://localhost:5173/#/reservar?company=felitobarber");
    }

    @Test
    void findPublicUrl_emptyWhenNoBusiness() {
        when(jdbcTemplate.query(anyString(), any(PreparedStatementSetter.class), any(RowMapper.class)))
            .thenReturn(Collections.emptyList());

        assertThat(resolver.findPublicUrl("t1")).isEmpty();
    }
}
