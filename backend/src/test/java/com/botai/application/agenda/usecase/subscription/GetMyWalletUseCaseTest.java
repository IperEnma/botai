package com.botai.application.agenda.usecase.subscription;

import com.botai.domain.agenda.exception.UserSubscriptionNotFoundException;
import com.botai.domain.agenda.model.CreditMotivo;
import com.botai.domain.agenda.model.CreditTransaction;
import com.botai.domain.agenda.model.SubscriptionEstado;
import com.botai.domain.agenda.model.UserSubscription;
import com.botai.domain.agenda.repository.CreditTransactionRepository;
import com.botai.domain.agenda.repository.UserSubscriptionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class GetMyWalletUseCaseTest {

    private UserSubscriptionRepository subscriptionRepository;
    private CreditTransactionRepository transactionRepository;
    private GetMyWalletUseCase useCase;

    private final UUID userId = UUID.randomUUID();
    private final UUID subscriptionId = UUID.randomUUID();
    private final LocalDateTime now = LocalDateTime.of(2026, 4, 20, 10, 0);

    @BeforeEach
    void setUp() {
        subscriptionRepository = mock(UserSubscriptionRepository.class);
        transactionRepository = mock(CreditTransactionRepository.class);
        useCase = new GetMyWalletUseCase(subscriptionRepository, transactionRepository);
    }

    private UserSubscription subOwnedBy(UUID ownerId) {
        return new UserSubscription(
                subscriptionId, ownerId, UUID.randomUUID(), UUID.randomUUID(),
                7, now, now.plusDays(30), SubscriptionEstado.ACTIVE, now, now);
    }

    @Test
    void devuelveSuscripcionYHistorialCuandoPerteneceAlUsuario() {
        CreditTransaction tx = new CreditTransaction(
                UUID.randomUUID(), subscriptionId, 10, CreditMotivo.COMPRA, null, now);
        when(subscriptionRepository.findById(subscriptionId))
                .thenReturn(Optional.of(subOwnedBy(userId)));
        when(transactionRepository.findAllBySubscriptionIdOrderByCreatedAtDesc(subscriptionId))
                .thenReturn(List.of(tx));

        GetMyWalletUseCase.Wallet wallet = useCase.execute(userId, subscriptionId);

        assertEquals(userId, wallet.subscription().getUserId());
        assertEquals(1, wallet.transactions().size());
        assertEquals(CreditMotivo.COMPRA, wallet.transactions().get(0).getMotivo());
        verify(transactionRepository).findAllBySubscriptionIdOrderByCreatedAtDesc(subscriptionId);
    }

    @Test
    void lanza404CuandoLaSuscripcionNoExiste() {
        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.empty());

        assertThrows(UserSubscriptionNotFoundException.class,
                () -> useCase.execute(userId, subscriptionId));
        verifyNoInteractions(transactionRepository);
    }

    @Test
    void lanza404CuandoLaSuscripcionEsDeOtroUsuario() {
        UUID otroUsuario = UUID.randomUUID();
        when(subscriptionRepository.findById(subscriptionId))
                .thenReturn(Optional.of(subOwnedBy(otroUsuario)));

        // 404, no 403: no revelamos su existencia.
        assertThrows(UserSubscriptionNotFoundException.class,
                () -> useCase.execute(userId, subscriptionId));
        verifyNoInteractions(transactionRepository);
    }
}
