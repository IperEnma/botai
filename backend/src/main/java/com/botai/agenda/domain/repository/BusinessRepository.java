package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.Business;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BusinessRepository {

    Business save(Business business);

    Optional<Business> findById(UUID id);

    Optional<Business> findByIdAndTenantId(UUID id, String tenantId);

    List<Business> findAllByTenantId(String tenantId);

    Optional<Business> findByPublicSlug(String publicSlug);

    boolean existsByIdAndTenantId(UUID id, String tenantId);

    void softDelete(UUID id);
}
