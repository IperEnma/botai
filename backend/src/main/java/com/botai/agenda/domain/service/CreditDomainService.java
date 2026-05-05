package com.botai.agenda.domain.service;

import com.botai.agenda.domain.exception.NoCreditsException;
import com.botai.agenda.domain.exception.SubscriptionExpiredException;
import com.botai.agenda.domain.model.CreditMotivo;
import com.botai.agenda.domain.model.CreditTransaction;
import com.botai.agenda.domain.model.Plan;
import com.botai.agenda.domain.model.PlanTipo;
import com.botai.agenda.domain.model.SubscriptionEstado;
import com.botai.agenda.domain.model.UserSubscription;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Reglas de negocio sobre créditos y vigencia de suscripciones.
 *
 * <p>Este service <b>no</b> persiste ni bloquea. Espera recibir una
 * {@link UserSubscription} ya bloqueada por el caller (el
 * {@code CreateBookingUseCase} pide {@code findByIdForUpdate} antes de
 * invocar) y devuelve un par (nueva suscripción, movimiento a grabar) listo
 * para que el caller lo guarde en la misma transacción.</p>
 *
 * <p>Reglas por tipo de plan:
 * <ul>
 *   <li>{@code POR_CREDITOS}/{@code MIXTO}: valida saldo &gt; 0 y descuenta 1.
 *       Movimiento con {@code monto=-1}.</li>
 *   <li>{@code ILIMITADO_MENSUAL}: no-op sobre el saldo, pero igual emite una
 *       {@code CreditTransaction(0, RESERVA)} para trazabilidad (cuántas
 *       veces usó el plan).</li>
 *   <li>{@code SOLO_RESERVA}: mismo tratamiento que ilimitado — no hay saldo
 *       que descontar, la reserva se registra pero no mueve la billetera.</li>
 * </ul>
 */
public class CreditDomainService {

    /**
     * Intenta descontar un crédito por el uso de una reserva. Devuelve la
     * suscripción actualizada y el movimiento a persistir. <b>No</b> los
     * graba — eso es responsabilidad del caller dentro de la misma tx.
     */
    public CreditDebit descontarPorReserva(UserSubscription subscription,
                                           Plan plan,
                                           UUID bookingId,
                                           LocalDateTime now) {
        validarVigencia(subscription, now);

        PlanTipo tipo = plan.getTipo();
        int nuevoSaldo = subscription.getSaldoActual();
        int monto = 0;

        if (tipo == PlanTipo.POR_CREDITOS || tipo == PlanTipo.MIXTO) {
            if (subscription.getSaldoActual() <= 0) {
                throw new NoCreditsException(subscription.getId());
            }
            nuevoSaldo = subscription.getSaldoActual() - 1;
            monto = -1;
        }
        // ILIMITADO_MENSUAL y SOLO_RESERVA → monto=0, saldo igual; la tx se
        // guarda igual para poder auditar uso del plan.

        UserSubscription updated = withSaldo(subscription, nuevoSaldo);
        CreditTransaction tx = new CreditTransaction(
                null, subscription.getId(), monto,
                CreditMotivo.RESERVA, bookingId, null
        );
        return new CreditDebit(updated, tx);
    }

    /**
     * Devolución por cancelación dentro de la ventana configurada. Solo suma
     * crédito para planes con billetera cuantitativa. Para ilimitado/solo
     * reserva, emite una tx con {@code monto=0} y motivo
     * {@code CANCELACION_DEVUELTA} para cerrar el rastro del booking.
     */
    public CreditDebit devolverPorCancelacion(UserSubscription subscription,
                                              Plan plan,
                                              UUID bookingId) {
        int monto = (plan.getTipo() == PlanTipo.POR_CREDITOS || plan.getTipo() == PlanTipo.MIXTO) ? 1 : 0;
        int nuevoSaldo = subscription.getSaldoActual() + monto;

        UserSubscription updated = withSaldo(subscription, nuevoSaldo);
        CreditTransaction tx = new CreditTransaction(
                null, subscription.getId(), monto,
                CreditMotivo.CANCELACION_DEVUELTA, bookingId, null
        );
        return new CreditDebit(updated, tx);
    }

    /**
     * Valida que la suscripción esté en estado {@code ACTIVE} y que la
     * fecha de expiración no haya pasado. Si alguna falla, tira
     * {@code SubscriptionExpiredException}.
     */
    public void validarVigencia(UserSubscription subscription, LocalDateTime now) {
        if (subscription.getEstado() != SubscriptionEstado.ACTIVE
                || subscription.getFechaExpiracion().isBefore(now)) {
            throw new SubscriptionExpiredException(subscription.getId());
        }
    }

    private static UserSubscription withSaldo(UserSubscription subscription, int nuevoSaldo) {
        return new UserSubscription(
                subscription.getId(),
                subscription.getUserId(),
                subscription.getPlanId(),
                subscription.getBusinessId(),
                nuevoSaldo,
                subscription.getFechaInicio(),
                subscription.getFechaExpiracion(),
                subscription.getEstado(),
                subscription.getCreatedAt(),
                subscription.getUpdatedAt()
        );
    }

    /**
     * Tupla inmutable: "suscripción ya actualizada" + "movimiento a persistir".
     */
    public record CreditDebit(UserSubscription subscription, CreditTransaction transaction) {
    }
}
