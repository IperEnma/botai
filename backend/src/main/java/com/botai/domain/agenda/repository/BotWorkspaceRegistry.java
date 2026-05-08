package com.botai.domain.agenda.repository;

import java.util.Optional;

/**
 * Resuelve el {@code bot.id} a partir del tenant único del workspace ({@code bot.tenant_id}),
 * para alinear Agenda, knowledge_chunk y conversaciones del bot.
 */
public interface BotWorkspaceRegistry {

    Optional<Long> findBotIdByWorkspaceTenantId(String workspaceTenantId);

    /**
     * Comprueba que {@code botId} exista y que {@code bot.tenant_id} coincida con el tenant Agenda dado.
     *
     * @throws com.botai.domain.agenda.exception.AgendaBotNotFoundException si no hay fila en {@code bot}
     * @throws com.botai.domain.agenda.exception.WorkspaceBotMismatchException si el tenant no coincide
     */
    void ensureBotBelongsToTenant(long botId, String tenantId);
}
