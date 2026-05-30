package com.botai.infrastructure.agenda.config;

import org.flywaydb.core.Flyway;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.autoconfigure.flyway.FlywayMigrationStrategy;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Hibernate ({@code ddl-auto=update}) crea las tablas {@code agenda_*}; Flyway aplica V1–V3
 * cuando la app está lista ({@link ApplicationReadyEvent}), no en el arranque automático de Spring.
 */
@Configuration
@ConditionalOnClass(Flyway.class)
@ConditionalOnProperty(name = "spring.flyway.enabled", havingValue = "true", matchIfMissing = true)
public class AgendaFlywayConfig {

    @Bean
    @ConditionalOnMissingBean(FlywayMigrationStrategy.class)
    public FlywayMigrationStrategy deferFlywayUntilApplicationReady() {
        return flyway -> { /* migrate() en el listener de abajo */ };
    }

    @Bean
    public ApplicationListener<ApplicationReadyEvent> agendaFlywayMigrateOnReady(
            Flyway flyway,
            @Value("${spring.flyway.repair-on-migrate:true}") boolean repairOnMigrate) {
        return event -> {
            if (repairOnMigrate) {
                flyway.repair();
            }
            flyway.migrate();
        };
    }
}
