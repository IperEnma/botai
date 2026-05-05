package com.botai.agenda.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Evento de dominio emitido cuando una reserva pasa a {@code CONFIRMED}.
 *
 * <p>Lo consume {@code LoyaltyDomainService} en Slice 3 para acumular
 * asistencias y sugerir renovación / captación cuando el usuario no tiene
 * suscripción activa.</p>
 *
 * <p>Se publica vía {@code ApplicationEventPublisher} de Spring <b>dentro</b>
 * de la misma transacción que crea la booking, usando
 * {@code @TransactionalEventListener(phase=AFTER_COMMIT)} en los listeners
 * para garantizar que nadie reacciona a un evento de una tx que rollbackeó.</p>
 */
public record BookingConfirmedEvent(
        UUID bookingId,
        UUID businessId,
        UUID userId,
        UUID subscriptionId,   // nullable
        LocalDateTime fechaHoraInicio
) {
}
