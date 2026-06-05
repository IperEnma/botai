package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.AgendaOtpChallengeEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface AgendaOtpChallengeJpaRepository extends JpaRepository<AgendaOtpChallengeEntity, UUID> {

    Optional<AgendaOtpChallengeEntity> findByTenantIdAndPhoneHash(String tenantId, String phoneHash);

    @Modifying
    @Query("delete from AgendaOtpChallengeEntity e where e.expiresAt < :cutoff")
    int deleteExpired(@Param("cutoff") LocalDateTime cutoff);
}
