package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.CreditTransaction;

import java.util.List;
import java.util.UUID;

/**
 * Puerto de persistencia para {@link CreditTransaction}. Nunca se actualiza: solo
 * {@code save} (insert) y lecturas por suscripción para historial/billetera.
 */
public interface CreditTransactionRepository {

    CreditTransaction save(CreditTransaction tx);

    List<CreditTransaction> findAllBySubscriptionIdOrderByCreatedAtDesc(UUID subscriptionId);
}
