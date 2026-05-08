package com.botai.application.agenda.usecase.bot;

import com.botai.domain.agenda.repository.BotWorkspaceRegistry;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;

/**
 * Vincula un bot del workspace ({@code bot.id}) con los negocios de Agenda que debe atender.
 */
@Service
public class LinkBotToAgendaBusinessesUseCase {

    private final BotWorkspaceRegistry botWorkspaceRegistry;
    private final BusinessRepository businessRepository;

    public LinkBotToAgendaBusinessesUseCase(BotWorkspaceRegistry botWorkspaceRegistry,
                                            BusinessRepository businessRepository) {
        this.botWorkspaceRegistry = botWorkspaceRegistry;
        this.businessRepository = businessRepository;
    }

    @Transactional
    public void execute(String tenantId, long botId, Set<UUID> businessIds) {
        botWorkspaceRegistry.ensureBotBelongsToTenant(botId, tenantId);
        Set<UUID> ids = (businessIds == null || businessIds.isEmpty())
                ? Set.of()
                : new LinkedHashSet<>(businessIds);
        businessRepository.replaceBotLinksForWorkspaceBot(tenantId, botId, ids);
    }
}
