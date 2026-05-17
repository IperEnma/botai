package com.botai.infrastructure.agenda.config;

import org.flywaydb.core.Flyway;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.autoconfigure.flyway.FlywayMigrationStrategy;
import org.springframework.context.ApplicationListener;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.event.ContextRefreshedEvent;

/**
 * Orden de arranque con JPA + Flyway:
 * <ol>
 *   <li>{@code schema.sql} — extensiones PG (vector, pgcrypto, …) vía Spring SQL init</li>
 *   <li>Hibernate {@code ddl-auto=update} — crea/actualiza tablas desde entidades</li>
 *   <li>Flyway V2–V4 — semilla de categorías, exclusión de slots, índices y FKs</li>
 * </ol>
 * V1 queda como baseline en el historial de Flyway (las extensiones ya las aplica schema.sql).
 */
@Configuration
@ConditionalOnClass(Flyway.class)
@ConditionalOnProperty(name = "spring.flyway.enabled", havingValue = "true", matchIfMissing = true)
public class AgendaFlywayConfig {

    /** Suprime la migración automática de Spring Boot; Flyway corre después de JPA. */
    @Bean
    @ConditionalOnMissingBean(FlywayMigrationStrategy.class)
    public FlywayMigrationStrategy agendaFlywayMigrationStrategy() {
        return flyway -> { /* migración completa en agendaFlywayAfterJpaMigrator */ };
    }

    /** Dispara Flyway tras la inicialización completa del contexto (JPA ya creó las tablas). */
    @Bean
    public ApplicationListener<ContextRefreshedEvent> agendaFlywayAfterJpaMigrator(
            Flyway flyway,
            @Value("${spring.flyway.repair-on-migrate:true}") boolean repairOnMigrate) {
        return new AgendaFlywayAfterJpaMigrator(flyway, repairOnMigrate);
    }

    private static final class AgendaFlywayAfterJpaMigrator
            implements ApplicationListener<ContextRefreshedEvent> {

        private final Flyway flyway;
        private final boolean repairOnMigrate;
        private volatile boolean migrated;

        AgendaFlywayAfterJpaMigrator(Flyway flyway, boolean repairOnMigrate) {
            this.flyway = flyway;
            this.repairOnMigrate = repairOnMigrate;
        }

        @Override
        public void onApplicationEvent(ContextRefreshedEvent event) {
            if (migrated || event.getApplicationContext().getParent() != null) return;
            if (repairOnMigrate) flyway.repair();
            flyway.migrate();
            migrated = true;
        }
    }
}
