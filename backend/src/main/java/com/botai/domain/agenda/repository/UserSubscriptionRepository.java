package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.SubscriptionEstado;
import com.botai.domain.agenda.model.UserSubscription;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Puerto de persistencia para {@link UserSubscription}. En Sprint 3 se agregará
 * {@code findByIdForUpdate(id)} con {@code PESSIMISTIC_WRITE} para reservas.
 */
public interface UserSubscriptionRepository {

    UserSubscription save(UserSubscription subscription);

    Optional<UserSubscription> findById(UUID id);

    /**
     * Misma semántica que {@link #findById(UUID)} pero bloqueando la fila
     * ({@code PESSIMISTIC_WRITE} / {@code SELECT ... FOR UPDATE}) hasta el fin
     * de la transacción actual. <b>Requiere</b> estar dentro de una tx, si no
     * el adapter levanta excepción.
     *
     * <p>Lo usa el flujo de reserva para evitar doble descuento cuando dos
     * requests compiten por el último crédito.</p>
     */
    Optional<UserSubscription> findByIdForUpdate(UUID id);

    List<UserSubscription> findAllByUserId(UUID userId);

    List<UserSubscription> findAllByUserIdAndEstado(UUID userId, SubscriptionEstado estado);

    List<UserSubscription> findAllByBusinessIdAndEstado(UUID businessId, SubscriptionEstado estado);

    /**
     * Suscripciones ACTIVE cuya fecha de expiración cae dentro del rango [desde, hasta].
     * Usado por el scheduler CU-02 para detectar vencimientos próximos.
     */
    List<UserSubscription> findAllActiveExpiringSoon(LocalDateTime desde, LocalDateTime hasta);

    /**
     * Suscripciones ACTIVE con saldo igual o inferior a {@code maxSaldo}.
     * Usado por el scheduler CU-02 para detectar saldos bajos.
     */
    List<UserSubscription> findAllActiveWithLowBalance(int maxSaldo);
}
