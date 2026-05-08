package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.Business;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

public interface BusinessRepository {

    Business save(Business business);

    Optional<Business> findById(UUID id);

    Optional<Business> findByIdAndTenantId(UUID id, String tenantId);

    List<Business> findAllByTenantId(String tenantId);

    Optional<Business> findByPublicSlug(String publicSlug);

    boolean existsByIdAndTenantId(UUID id, String tenantId);

    void softDelete(UUID id);

    /**
     * Deja {@code bot_id = botId} solo en los negocios indicados (mismo {@code tenant_id}).
     * En el resto de negocios del tenant que tenían ese {@code botId}, lo pone en NULL.
     * Lista vacía = desvincular todos los negocios de ese bot en el tenant.
     */
    void replaceBotLinksForWorkspaceBot(String tenantId, long botId, Set<UUID> businessIds);
}
