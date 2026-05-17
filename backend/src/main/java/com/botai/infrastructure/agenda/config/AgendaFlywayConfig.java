package com.botai.infrastructure.agenda.config;

import org.flywaydb.core.Flyway;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;
import org.springframework.beans.factory.support.AbstractBeanDefinition;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.flyway.FlywayMigrationStrategy;
import org.springframework.context.ApplicationListener;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.event.ContextRefreshedEvent;

import javax.sql.DataSource;
import java.util.LinkedHashSet;
import java.util.Set;

/**
 * Orden de arranque con JPA + Flyway (Spring Boot 3.2):
 * <ol>
 *   <li>{@link AgendaPostgresExtensions} — V1 (vector, btree_gist, …)</li>
 *   <li>Hibernate {@code ddl-auto=update} — tablas desde entidades</li>
 *   <li>Flyway V2–V4 — semilla, EXCLUDE, índices/FKs</li>
 * </ol>
 * {@code defer-datasource-initialization} queda en {@code false} para evitar el ciclo
 * EMF↔Flyway que rompe el deploy (p. ej. Render).
 */
@Configuration
@ConditionalOnClass(Flyway.class)
public class AgendaFlywayConfig {

    @Bean(name = "agendaPostgresExtensions")
    public Object agendaPostgresExtensions(DataSource dataSource) {
        AgendaPostgresExtensions.apply(dataSource);
        return new Object();
    }

    @Bean
    public static BeanFactoryPostProcessor agendaEntityManagerFactoryDependsOnExtensions() {
        return AgendaFlywayConfig::addExtensionsDependencyToEntityManagerFactory;
    }

    @Bean
    @ConditionalOnMissingBean(FlywayMigrationStrategy.class)
    public FlywayMigrationStrategy agendaFlywayMigrationStrategy() {
        return flyway -> { /* migración completa en agendaFlywayAfterJpaMigrator */ };
    }

    @Bean
    public ApplicationListener<ContextRefreshedEvent> agendaFlywayAfterJpaMigrator(
            Flyway flyway,
            @org.springframework.beans.factory.annotation.Value("${spring.flyway.repair-on-migrate:true}")
            boolean repairOnMigrate) {
        return new AgendaFlywayAfterJpaMigrator(flyway, repairOnMigrate);
    }

    private static void addExtensionsDependencyToEntityManagerFactory(
            ConfigurableListableBeanFactory beanFactory) {
        if (!beanFactory.containsBeanDefinition("entityManagerFactory")) {
            return;
        }
        BeanDefinition definition = beanFactory.getBeanDefinition("entityManagerFactory");
        if (!(definition instanceof AbstractBeanDefinition abstractDefinition)) {
            return;
        }
        Set<String> dependsOn = new LinkedHashSet<>();
        if (abstractDefinition.getDependsOn() != null) {
            dependsOn.addAll(Set.of(abstractDefinition.getDependsOn()));
        }
        dependsOn.add("agendaPostgresExtensions");
        abstractDefinition.setDependsOn(dependsOn.toArray(String[]::new));
    }

    private static final class AgendaFlywayAfterJpaMigrator implements ApplicationListener<ContextRefreshedEvent> {

        private final Flyway flyway;
        private final boolean repairOnMigrate;
        private volatile boolean migrated;

        AgendaFlywayAfterJpaMigrator(Flyway flyway, boolean repairOnMigrate) {
            this.flyway = flyway;
            this.repairOnMigrate = repairOnMigrate;
        }

        @Override
        public void onApplicationEvent(ContextRefreshedEvent event) {
            if (migrated || event.getApplicationContext().getParent() != null) {
                return;
            }
            if (repairOnMigrate) {
                flyway.repair();
            }
            flyway.migrate();
            migrated = true;
        }
    }
}
