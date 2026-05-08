package com.botai.infrastructure.agenda.support;

import com.botai.infrastructure.agenda.persistence.entity.BusinessEntity;
import com.botai.infrastructure.agenda.persistence.jpa.BusinessJpaRepository;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Negocio principal del tenant en Agenda (el más antiguo por {@code created_at} entre activos y no borrados).
 * Misma regla que la materialización RAG de agenda.
 */
@Component
public class AgendaPrimaryBusinessResolver {

    private final BusinessJpaRepository businessRepository;

    public AgendaPrimaryBusinessResolver(BusinessJpaRepository businessRepository) {
        this.businessRepository = businessRepository;
    }

    public Optional<UUID> findPrimaryBusinessId(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return Optional.empty();
        }
        List<BusinessEntity> list = businessRepository.findAllByTenantIdAndDeletedAtIsNull(tenantId);
        return list.stream()
            .filter(BusinessEntity::isActivo)
            .min(Comparator.comparing(BusinessEntity::getCreatedAt, Comparator.nullsLast(Comparator.naturalOrder())))
            .map(BusinessEntity::getId);
    }
}
