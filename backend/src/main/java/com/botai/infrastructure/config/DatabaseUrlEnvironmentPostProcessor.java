package com.botai.infrastructure.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.util.Map;

/**
 * Neon, Render y Heroku suelen exponer {@code DATABASE_URL} como {@code postgresql://...}.
 * HikariCP y el driver JDBC de PostgreSQL requieren {@code jdbc:postgresql://...}.
 */
public class DatabaseUrlEnvironmentPostProcessor implements EnvironmentPostProcessor {

    static final String ENV_DATABASE_URL = "DATABASE_URL";
    static final String PROP_SPRING_DATASOURCE_URL = "spring.datasource.url";

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        String raw = environment.getProperty(ENV_DATABASE_URL);
        if (raw == null || raw.isBlank()) {
            return;
        }
        String jdbcUrl = toJdbcUrl(raw.trim());
        if (jdbcUrl.equals(raw.trim())) {
            return;
        }
        environment.getPropertySources().addFirst(
                new MapPropertySource("normalizedDatabaseUrl", Map.of(
                        ENV_DATABASE_URL, jdbcUrl,
                        PROP_SPRING_DATASOURCE_URL, jdbcUrl)));
    }

    static String toJdbcUrl(String url) {
        if (url.startsWith("jdbc:")) {
            return url;
        }
        if (url.startsWith("postgresql://") || url.startsWith("postgres://")) {
            return "jdbc:" + url;
        }
        return url;
    }
}
