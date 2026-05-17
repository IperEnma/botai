package com.botai.testsupport;

import org.flywaydb.core.Flyway;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.autoconfigure.flyway.FlywayMigrationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

/**
 * Tests: no migrar en el arranque de Flyway (evita correr antes que Hibernate); {@link AgendaTestFlywayMigrator}
 * aplica migraciones tras el contexto listo.
 */
@Configuration
@Profile("test")
@ConditionalOnProperty(name = "agenda.test.flyway-after-jpa", havingValue = "true")
public class AgendaTestFlywayConfig {

    @Bean
    public FlywayMigrationStrategy agendaTestFlywayMigrationStrategy() {
        return flyway -> { /* defer to AgendaTestFlywayMigrator */ };
    }
}
