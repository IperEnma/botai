package com.botai.agenda;

import com.botai.agenda.domain.repository.BookingRepository;
import com.botai.agenda.domain.service.BookingDomainService;
import com.botai.agenda.domain.service.CancellationDomainService;
import com.botai.agenda.domain.service.CreditDomainService;
import com.botai.agenda.domain.service.LoyaltyDomainService;
import org.springframework.boot.autoconfigure.AutoConfigureAfter;
import org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.time.Clock;

/**
 * Punto de entrada del módulo AGENDA como auto-configuración de Spring Boot.
 *
 * <p>Solo dispara el {@code @ComponentScan} del paquete {@code com.botai.agenda}
 * y registra los domain-services puros. Las anotaciones JPA
 * ({@code @EnableJpaRepositories}, {@code @EntityScan}, {@code @EnableJpaAuditing})
 * viven en {@link com.botai.agenda.infrastructure.config.AgendaJpaConfig}, que es
 * descubierta por este scan y se procesa como {@code @Configuration} ordinaria
 * (fuera de la fase de auto-configuración), evitando la dependencia circular
 * {@code entityManagerFactory ↔ flyway}.</p>
 */
@Configuration
@AutoConfigureAfter(FlywayAutoConfiguration.class)
@ComponentScan(basePackages = "com.botai.agenda")
@EnableScheduling
public class AgendaModuleConfig {

    @Bean
    public Clock agendaClock() {
        return Clock.systemDefaultZone();
    }

    @Bean
    public CreditDomainService creditDomainService() {
        return new CreditDomainService();
    }

    @Bean
    public BookingDomainService bookingDomainService(BookingRepository bookingRepository) {
        return new BookingDomainService(bookingRepository);
    }

    @Bean
    public CancellationDomainService cancellationDomainService() {
        return new CancellationDomainService();
    }

    @Bean
    public LoyaltyDomainService loyaltyDomainService() {
        return new LoyaltyDomainService();
    }
}
