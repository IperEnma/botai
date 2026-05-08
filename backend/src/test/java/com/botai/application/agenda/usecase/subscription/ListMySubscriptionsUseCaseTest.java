package com.botai.application.agenda.usecase.subscription;

import com.botai.domain.agenda.model.SubscriptionEstado;
import com.botai.domain.agenda.model.UserSubscription;
import com.botai.domain.agenda.repository.UserSubscriptionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ListMySubscriptionsUseCaseTest {

    private UserSubscriptionRepository subscriptionRepository;
    private ListMySubscriptionsUseCase useCase;

    private final UUID userId = UUID.randomUUID();
    private final LocalDateTime now = LocalDateTime.of(2026, 4, 20, 10, 0);

    @BeforeEach
    void setUp() {
        subscriptionRepository = mock(UserSubscriptionRepository.class);
        useCase = new ListMySubscriptionsUseCase(subscriptionRepository);
    }

    private UserSubscription sub(SubscriptionEstado estado) {
        return new UserSubscription(
                UUID.randomUUID(), userId, UUID.randomUUID(), UUID.randomUUID(),
                5, now, now.plusDays(30), estado, now, now);
    }

    @Test
    void devuelveTodasCuandoOnlyActiveEsFalse() {
        when(subscriptionRepository.findAllByUserId(userId))
                .thenReturn(List.of(sub(SubscriptionEstado.ACTIVE), sub(SubscriptionEstado.EXPIRED)));

        List<UserSubscription> result = useCase.execute(userId, false);

        assertEquals(2, result.size());
        verify(subscriptionRepository).findAllByUserId(userId);
    }

    @Test
    void filtraPorActivasCuandoOnlyActiveEsTrue() {
        when(subscriptionRepository.findAllByUserIdAndEstado(userId, SubscriptionEstado.ACTIVE))
                .thenReturn(List.of(sub(SubscriptionEstado.ACTIVE)));

        List<UserSubscription> result = useCase.execute(userId, true);

        assertEquals(1, result.size());
        verify(subscriptionRepository).findAllByUserIdAndEstado(userId, SubscriptionEstado.ACTIVE);
    }
}
