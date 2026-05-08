package com.botai.infrastructure.agenda.config;

import org.flywaydb.core.Flyway;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.flyway.FlywayMigrationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Spring Boot 3.2.x {@code FlywayProperties} no expone {@code repair-on-migrate}, así que
 * la clave en {@code application.yml} no llega al bean de Flyway. Tras reescribir migraciones
 * ya aplicadas hace falta {@link Flyway#repair()} antes de {@link Flyway#migrate()} para
 * alinear checksums en {@code agenda_flyway_schema_history}.
 */
@Configuration
@ConditionalOnClass(Flyway.class)
public class AgendaFlywayConfig {

    @Bean
    @ConditionalOnMissingBean(FlywayMigrationStrategy.class)
    public FlywayMigrationStrategy agendaFlywayMigrationStrategy(
            @Value("${spring.flyway.repair-on-migrate:true}") boolean repairOnMigrate) {
        return flyway -> {
            if (repairOnMigrate) {
                flyway.repair();
            }
            flyway.migrate();
        };
    }
}
