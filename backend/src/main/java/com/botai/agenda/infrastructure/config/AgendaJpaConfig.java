package com.botai.agenda.infrastructure.config;

import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * Configuración JPA del módulo AGENDA.
 *
 * <p>Separada de {@link com.botai.agenda.AgendaModuleConfig} (auto-configuración)
 * para evitar la dependencia circular {@code entityManagerFactory ↔ flyway}.
 * Al vivir aquí, es descubierta por el {@code @ComponentScan} de
 * {@code AgendaModuleConfig} y procesada como {@code @Configuration} ordinaria,
 * fuera de la fase de auto-configuración y después de que Flyway ya corrió.</p>
 */
@Configuration
@EnableJpaAuditing
@EnableJpaRepositories(basePackages = "com.botai")
@EntityScan(basePackages = "com.botai")
public class AgendaJpaConfig {
}
