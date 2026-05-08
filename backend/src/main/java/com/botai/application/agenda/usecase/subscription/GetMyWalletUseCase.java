package com.botai.application.agenda.usecase.subscription;

import com.botai.domain.agenda.exception.UserSubscriptionNotFoundException;
import com.botai.domain.agenda.model.CreditTransaction;
import com.botai.domain.agenda.model.UserSubscription;
import com.botai.domain.agenda.repository.CreditTransactionRepository;
import com.botai.domain.agenda.repository.UserSubscriptionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Detalle de "mi billetera": una suscripción del usuario + el libro mayor
 * completo de sus transacciones (compra, reservas, devoluciones, ajustes).
 *
 * <p>El check de ownership es crítico: si la suscripción existe pero es de
 * otro usuario, devolvemos 404 (no 403) para no revelar su existencia.</p>
 */
@Service
public class GetMyWalletUseCase {

    private final UserSubscriptionRepository subscriptionRepository;
    private final CreditTransactionRepository transactionRepository;

    public GetMyWalletUseCase(UserSubscriptionRepository subscriptionRepository,
                              CreditTransactionRepository transactionRepository) {
        this.subscriptionRepository = subscriptionRepository;
        this.transactionRepository = transactionRepository;
    }

    @Transactional(readOnly = true)
    public Wallet execute(UUID userId, UUID subscriptionId) {
        UserSubscription sub = subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new UserSubscriptionNotFoundException(subscriptionId));
        if (!sub.getUserId().equals(userId)) {
            // No exponer que existe bajo otro usuario.
            throw new UserSubscriptionNotFoundException(subscriptionId);
        }
        List<CreditTransaction> history =
                transactionRepository.findAllBySubscriptionIdOrderByCreatedAtDesc(subscriptionId);
        return new Wallet(sub, history);
    }

    public record Wallet(UserSubscription subscription, List<CreditTransaction> transactions) {
    }
}
