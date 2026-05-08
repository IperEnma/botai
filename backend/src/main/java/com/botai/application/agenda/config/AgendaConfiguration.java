package com.botai.application.agenda.config;

import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.service.BookingDomainService;
import com.botai.domain.agenda.service.CancellationDomainService;
import com.botai.domain.agenda.service.CreditDomainService;
import com.botai.domain.agenda.service.LoyaltyDomainService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.time.Clock;

/**
 * Beans de dominio AGENDA (servicios de dominio + {@link Clock}) cableados en Spring.
 * JPA ({@code @EnableJpaRepositories}, etc.) está en
 * {@link com.botai.infrastructure.agenda.config.AgendaJpaConfig}.
 */
@Configuration
@EnableScheduling
public class AgendaConfiguration {

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
