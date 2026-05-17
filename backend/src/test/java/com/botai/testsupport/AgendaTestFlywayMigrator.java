package com.botai.testsupport;

import org.flywaydb.core.Flyway;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.stereotype.Component;

/**
 * En tests: Hibernate crea tablas ({@code ddl-auto=update}) y luego Flyway aplica semilla/EXCLUDE/V4.
 * Evita el ciclo EMF↔Flyway de {@code defer-datasource-initialization} con
 * {@code spring.flyway.enabled=false} en {@code application-test.yml}.
 */
@Component
@ConditionalOnProperty(name = "agenda.test.flyway-after-jpa", havingValue = "true")
public class AgendaTestFlywayMigrator implements ApplicationListener<ContextRefreshedEvent> {

    private final Flyway flyway;
    private volatile boolean migrated;

    public AgendaTestFlywayMigrator(Flyway flyway) {
        this.flyway = flyway;
    }

    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        if (migrated || event.getApplicationContext().getParent() != null) {
            return;
        }
        if (Boolean.TRUE.equals(
                event.getApplicationContext().getEnvironment()
                        .getProperty("spring.flyway.repair-on-migrate", Boolean.class, true))) {
            flyway.repair();
        }
        flyway.migrate();
        migrated = true;
    }
}
