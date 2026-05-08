package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.ServiceEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Spring Data: bean explícito por si en el futuro hay otro repo con el mismo simple name. */
@Repository("agendaServiceJpaRepository")
public interface ServiceJpaRepository extends JpaRepository<ServiceEntity, UUID> {

    Optional<ServiceEntity> findByIdAndDeletedAtIsNull(UUID id);

    List<ServiceEntity> findAllByBusinessIdAndDeletedAtIsNull(UUID businessId);

    List<ServiceEntity> findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(UUID businessId);

    @Modifying
    @Query("UPDATE AgendaService s SET s.deletedAt = CURRENT_TIMESTAMP, s.activo = false WHERE s.id = :id")
    int softDelete(@Param("id") UUID id);
}
