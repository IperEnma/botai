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

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Orden de arranque con JPA + Flyway:
 * <ol>
 *   <li>{@code schema.sql} — extensiones PG (vector, pgcrypto, …) vía Spring SQL init</li>
 *   <li>Hibernate {@code ddl-auto} — crea/actualiza tablas desde entidades</li>
 *   <li>Flyway V1–Vn — semilla de categorías, FKs, índices, etc.</li>
 * </ol>
 *
 * <p>Con {@code agenda.flyway.clean-history-before-migrate=true} (perfil local) el historial
 * de Flyway se elimina antes de migrar, forzando que todas las migraciones corran de nuevo.
 * Combinado con {@code ddl-auto: create-drop} garantiza un esquema limpio en cada reinicio
 * sin necesidad de migraciones ALTER TABLE/COLUMN en desarrollo.
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
            DataSource dataSource,
            @Value("${spring.flyway.repair-on-migrate:true}") boolean repairOnMigrate,
            @Value("${spring.flyway.table:agenda_flyway_schema_history}") String historyTable,
            @Value("${agenda.flyway.clean-history-before-migrate:false}") boolean cleanHistoryBeforeMigrate) {
        return new AgendaFlywayAfterJpaMigrator(flyway, dataSource, repairOnMigrate, historyTable, cleanHistoryBeforeMigrate);
    }

    private static final class AgendaFlywayAfterJpaMigrator
            implements ApplicationListener<ContextRefreshedEvent> {

        private final Flyway flyway;
        private final DataSource dataSource;
        private final boolean repairOnMigrate;
        private final String historyTable;
        private final boolean cleanHistoryBeforeMigrate;
        private volatile boolean migrated;

        AgendaFlywayAfterJpaMigrator(Flyway flyway, DataSource dataSource,
                                      boolean repairOnMigrate, String historyTable,
                                      boolean cleanHistoryBeforeMigrate) {
            this.flyway = flyway;
            this.dataSource = dataSource;
            this.repairOnMigrate = repairOnMigrate;
            this.historyTable = historyTable;
            this.cleanHistoryBeforeMigrate = cleanHistoryBeforeMigrate;
        }

        @Override
        public void onApplicationEvent(ContextRefreshedEvent event) {
            if (migrated || event.getApplicationContext().getParent() != null) return;
            if (cleanHistoryBeforeMigrate) dropHistoryTable();
            if (repairOnMigrate) flyway.repair();
            flyway.migrate();
            migrated = true;
        }

        private void dropHistoryTable() {
            try (Connection conn = dataSource.getConnection();
                 Statement stmt = conn.createStatement()) {
                stmt.execute("DROP TABLE IF EXISTS \"" + historyTable + "\"");
            } catch (SQLException e) {
                throw new IllegalStateException("No se pudo limpiar el historial de Flyway: " + historyTable, e);
            }
        }
    }
}
