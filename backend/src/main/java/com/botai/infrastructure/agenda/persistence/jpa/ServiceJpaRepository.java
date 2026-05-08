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

/**
 * <p><b>Por qué {@code @Repository("agendaServiceJpaRepository")}:</b> el bot
 * tiene un interface con el mismo simple name en
 * {@code com.botai.infrastructure.chatbot.persistence.jpa.ServiceJpaRepository}.
 * Spring Data genera el bean name a partir del simple name (decapitalizado),
 * así que ambos se llamarían {@code serviceJpaRepository} y colisionarían al
 * arrancar el contexto con {@code BeanDefinitionOverrideException}. Nombramos
 * explícitamente el bean de AGENDA para evitar el choque sin tocar código del
 * bot. La inyección en los adapters es por tipo, así que el bean name explícito
 * no afecta el wiring.</p>
 */
@Repository("agendaServiceJpaRepository")
public interface ServiceJpaRepository extends JpaRepository<ServiceEntity, UUID> {

    Optional<ServiceEntity> findByIdAndDeletedAtIsNull(UUID id);

    List<ServiceEntity> findAllByBusinessIdAndDeletedAtIsNull(UUID businessId);

    List<ServiceEntity> findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(UUID businessId);

    @Modifying
    @Query("UPDATE AgendaService s SET s.deletedAt = CURRENT_TIMESTAMP, s.activo = false WHERE s.id = :id")
    int softDelete(@Param("id") UUID id);
}
