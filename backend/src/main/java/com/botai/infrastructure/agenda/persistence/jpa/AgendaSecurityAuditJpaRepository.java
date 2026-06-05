package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.AgendaSecurityAuditEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.UUID;

public interface AgendaSecurityAuditJpaRepository extends JpaRepository<AgendaSecurityAuditEntity, UUID> {

    long countByPhoneHashAndEventTypeAndCreatedAtAfter(
            String phoneHash, String eventType, LocalDateTime since);

    long countByClientIpAndEventTypeAndCreatedAtAfter(
            String clientIp, String eventType, LocalDateTime since);

    @Modifying
    @Query("delete from AgendaSecurityAuditEntity e where e.createdAt < :cutoff")
    int deleteOlderThan(@Param("cutoff") LocalDateTime cutoff);
}
