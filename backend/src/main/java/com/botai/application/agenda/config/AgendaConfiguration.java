package com.botai.application.agenda.config;

import com.botai.domain.agenda.exception.AgendaBotNotFoundException;
import com.botai.domain.agenda.exception.WorkspaceBotMismatchException;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BotWorkspaceRegistry;
import com.botai.domain.agenda.service.BookingDomainService;
import com.botai.domain.agenda.service.CancellationDomainService;
import com.botai.domain.agenda.service.CreditDomainService;
import com.botai.domain.agenda.service.LoyaltyDomainService;
import com.botai.infrastructure.chatbot.persistence.entity.BotEntity;
import com.botai.infrastructure.chatbot.persistence.jpa.BotJpaRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.time.Clock;
import java.util.Optional;

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

    @Bean
    public BotWorkspaceRegistry botWorkspaceRegistry(BotJpaRepository botJpaRepository) {
        return new BotWorkspaceRegistry() {
            @Override
            public Optional<Long> findBotIdByWorkspaceTenantId(String workspaceTenantId) {
                if (workspaceTenantId == null || workspaceTenantId.isBlank()) {
                    return Optional.empty();
                }
                return botJpaRepository.findByTenantId(workspaceTenantId.strip()).map(BotEntity::getId);
            }

            @Override
            public void ensureBotBelongsToTenant(long botId, String tenantId) {
                BotEntity bot = botJpaRepository.findById(botId)
                        .orElseThrow(() -> new AgendaBotNotFoundException(botId));
                if (tenantId == null || !tenantId.equals(bot.getTenantId())) {
                    throw new WorkspaceBotMismatchException();
                }
            }
        };
    }
}
