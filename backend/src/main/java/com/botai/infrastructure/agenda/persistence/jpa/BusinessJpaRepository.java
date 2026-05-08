package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.BusinessEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Spring Data interface para {@link BusinessEntity}.
 * Queries que respetan el {@code deleted_at IS NULL} (soft delete).
 */
public interface BusinessJpaRepository extends JpaRepository<BusinessEntity, UUID> {

    Optional<BusinessEntity> findByIdAndTenantIdAndDeletedAtIsNull(UUID id, String tenantId);

    List<BusinessEntity> findAllByTenantIdAndDeletedAtIsNull(String tenantId);

    Optional<BusinessEntity> findByPublicSlugAndDeletedAtIsNull(String publicSlug);

    boolean existsByIdAndTenantIdAndDeletedAtIsNull(UUID id, String tenantId);

    @Modifying
    @Query("UPDATE BusinessEntity b SET b.deletedAt = CURRENT_TIMESTAMP WHERE b.id = :id")
    int softDelete(@Param("id") UUID id);
}
