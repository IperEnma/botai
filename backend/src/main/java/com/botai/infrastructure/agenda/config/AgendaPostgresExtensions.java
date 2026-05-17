package com.botai.infrastructure.agenda.config;

import javax.sql.DataSource;
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
 * Ejecuta Flyway V1 ({@code V1__postgresql_extensions.sql}) antes de que Hibernate cree tablas
 * con tipos {@code vector}. Idempotente ({@code IF NOT EXISTS}).
 */
public final class AgendaPostgresExtensions {

    static final String V1_CLASSPATH = "/db/migration/agenda/V1__postgresql_extensions.sql";

    private AgendaPostgresExtensions() {}

    public static void apply(DataSource dataSource) {
        try (Connection conn = dataSource.getConnection()) {
            executeSql(conn);
        } catch (SQLException e) {
            throw new IllegalStateException(
                    "No se pudieron crear las extensiones PostgreSQL (V1). "
                            + "En Neon activá pgvector en el proyecto; en local usá pgvector/pgvector:pg16.", e);
        }
    }

    public static void apply(String jdbcUrl, String username, String password) {
        try (Connection conn = DriverManager.getConnection(jdbcUrl, username, password)) {
            executeSql(conn);
        } catch (SQLException e) {
            throw new IllegalStateException(
                    "No se pudieron crear las extensiones PostgreSQL (V1).", e);
        }
    }

    private static void executeSql(Connection conn) throws SQLException {
        String sql = loadV1Script();
        String executable = Arrays.stream(sql.split("\n"))
                .map(String::trim)
                .filter(line -> !line.isEmpty() && !line.startsWith("--"))
                .collect(Collectors.joining("\n"));
        try (Statement st = conn.createStatement()) {
            for (String statement : executable.split(";")) {
                String trimmed = statement.trim();
                if (!trimmed.isEmpty()) {
                    st.execute(trimmed);
                }
            }
        }
    }

    private static String loadV1Script() {
        try (InputStream in = AgendaPostgresExtensions.class.getResourceAsStream(V1_CLASSPATH)) {
            if (in == null) {
                throw new IllegalStateException("Recurso no encontrado: " + V1_CLASSPATH);
            }
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo leer " + V1_CLASSPATH, e);
        }
    }
}
