package com.botai.infrastructure.agenda.config;

import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * Configuración JPA del paquete AGENDA (mismo proceso que el bot).
 * Descubierta por el component-scan por defecto desde {@link com.botai.ChatbotEngineApplication}.
 */
@Configuration
@EnableJpaAuditing
@EnableJpaRepositories(basePackages = "com.botai")
@EntityScan(basePackages = "com.botai")
public class AgendaJpaConfig {
}
