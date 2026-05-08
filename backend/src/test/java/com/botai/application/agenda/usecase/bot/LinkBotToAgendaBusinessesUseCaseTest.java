package com.botai.application.agenda.usecase.bot;

import com.botai.domain.agenda.repository.BotWorkspaceRegistry;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class LinkBotToAgendaBusinessesUseCaseTest {

    @Mock
    private BotWorkspaceRegistry botWorkspaceRegistry;
    @Mock
    private BusinessRepository businessRepository;

    private LinkBotToAgendaBusinessesUseCase useCase;

    @BeforeEach
    void setUp() {
        useCase = new LinkBotToAgendaBusinessesUseCase(botWorkspaceRegistry, businessRepository);
    }

    @Test
    void execute_verifiesBotThenReplacesLinks() {
        String tenant = "tenant-a";
        long botId = 9L;
        UUID b1 = UUID.randomUUID();
        Set<UUID> ids = new LinkedHashSet<>(Set.of(b1));

        useCase.execute(tenant, botId, ids);

        verify(botWorkspaceRegistry).ensureBotBelongsToTenant(botId, tenant);
        verify(businessRepository).replaceBotLinksForWorkspaceBot(tenant, botId, ids);
    }

    @Test
    void execute_nullBusinessIds_passesEmptySet() {
        useCase.execute("t", 1L, null);
        verify(botWorkspaceRegistry).ensureBotBelongsToTenant(1L, "t");
        verify(businessRepository).replaceBotLinksForWorkspaceBot(eq("t"), eq(1L), eq(Set.of()));
    }
}
