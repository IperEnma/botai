package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.AgendaClientSessionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface AgendaClientSessionJpaRepository extends JpaRepository<AgendaClientSessionEntity, UUID> {

    Optional<AgendaClientSessionEntity> findByTokenHash(String tokenHash);

    @Modifying
    @Query("delete from AgendaClientSessionEntity e where e.expiresAt < :cutoff")
    int deleteExpired(@Param("cutoff") LocalDateTime cutoff);
}
