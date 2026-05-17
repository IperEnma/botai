package com.botai.testsupport;

import org.testcontainers.containers.JdbcDatabaseContainer;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * Aplica {@code V1__postgresql_extensions.sql} antes del contexto Spring (mismo archivo que Flyway V1).
 * Requiere imagen {@code pgvector/pgvector:pg16}.
 */
public final class PostgresExtensions {

    private static final String RESOURCE = "/db/migration/agenda/V1__postgresql_extensions.sql";

    private PostgresExtensions() {}

    public static void ensure(JdbcDatabaseContainer<?> postgres) {
        if (!postgres.isRunning()) {
            postgres.start();
        }
        String sql = loadSql();
        try (Connection conn = DriverManager.getConnection(
                postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword());
             Statement st = conn.createStatement()) {
            String executable = Arrays.stream(sql.split("\n"))
                    .map(String::trim)
                    .filter(line -> !line.isEmpty() && !line.startsWith("--"))
                    .collect(Collectors.joining("\n"));
            for (String statement : executable.split(";")) {
                String trimmed = statement.trim();
                if (!trimmed.isEmpty()) {
                    st.execute(trimmed);
                }
            }
        } catch (SQLException e) {
            throw new IllegalStateException(
                    "No se pudieron crear extensiones PG en Testcontainers. "
                            + "Usa imagen pgvector/pgvector:pg16 (ver AbstractAgendaIntegrationTest).", e);
        }
    }

    private static String loadSql() {
        try (InputStream in = PostgresExtensions.class.getResourceAsStream(RESOURCE)) {
            if (in == null) {
                throw new IllegalStateException("Recurso no encontrado en classpath: " + RESOURCE);
            }
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo leer " + RESOURCE, e);
        }
    }
}
