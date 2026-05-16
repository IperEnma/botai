package com.botai.infrastructure.agenda.scheduler;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Elimina filas de {@code agenda_idempotency_keys} con más de N horas de antigüedad.
 * Se ejecuta una vez por día a medianoche.
 */
@Component
@ConditionalOnProperty(name = "agenda.outbox.scheduler.enabled", havingValue = "true", matchIfMissing = true)
public class IdempotencyCleanupScheduler {

    private static final Logger log = LoggerFactory.getLogger(IdempotencyCleanupScheduler.class);

    private final JdbcTemplate jdbc;
    private final int ttlHours;

    public IdempotencyCleanupScheduler(JdbcTemplate jdbc,
                                        @Value("${agenda.idempotency.ttl-hours:24}") int ttlHours) {
        this.jdbc     = jdbc;
        this.ttlHours = ttlHours;
    }

    @Scheduled(cron = "0 0 0 * * *")
    public void cleanup() {
        int deleted = jdbc.update(
                "DELETE FROM agenda_idempotency_keys WHERE created_at < now() - INTERVAL '" + ttlHours + " hours'");
        if (deleted > 0) {
            log.info("AGENDA idempotency: {} clave(s) eliminada(s) (ttl={}h)", deleted, ttlHours);
        }
    }
}
