package com.botai.agenda.infrastructure.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.util.Map;

/**
 * Desactiva {@code spring.jpa.defer-datasource-initialization} antes de que el
 * contexto de Spring se construya.
 *
 * Con {@code defer=true} + Flyway en classpath, Spring Boot crea una cadena de
 * depends-on circular:
 *   entityManagerFactory → flyway … dataSourceScriptDatabaseInitializer → entityManagerFactory
 *
 * Al forzar {@code defer=false} los scripts SQL (schema.sql / data.sql del bot)
 * se ejecutan antes de JPA, lo cual es seguro porque schema.sql usa IF NOT EXISTS.
 */
public class AgendaEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment,
                                       SpringApplication application) {
        environment.getPropertySources().addFirst(
            new MapPropertySource("agendaBootOverrides", Map.of(
                // Breaks the entityManagerFactory ↔ flyway circular depends-on that
                // occurs when both Flyway and spring.sql.init are active together.
                "spring.jpa.defer-datasource-initialization", "false",
                // Let standard FlywayAutoConfiguration manage the flyway bean,
                // pointed at the AGENDA migration directory with its own history table.
                "spring.flyway.locations", "classpath:db/migration/agenda",
                "spring.flyway.table", "agenda_flyway_schema_history",
                "spring.flyway.baseline-on-migrate", "true",
                "spring.flyway.baseline-version", "0",
                "spring.flyway.validate-on-migrate", "true"
            ))
        );
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}
