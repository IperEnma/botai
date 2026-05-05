package com.botai.agenda.domain.service;

import com.botai.agenda.domain.exception.BookingNotCancellableException;
import com.botai.agenda.domain.exception.CancellationNotAllowedException;
import com.botai.agenda.domain.model.Booking;
import com.botai.agenda.domain.model.BookingEstado;
import com.botai.agenda.domain.model.BusinessSettings;

import java.time.LocalDateTime;

/**
 * Reglas de dominio para cancelar una reserva.
 *
 * <p>Verifica dos invariantes antes de construir el objeto cancelado:
 * <ol>
 *   <li>La reserva debe estar en estado cancelable (PENDING o CONFIRMED).</li>
 *   <li>El momento de cancelación debe ser anterior a la ventana de corte
 *       ({@code fechaHoraInicio - hoursCancellationLimit}).</li>
 * </ol>
 *
 * <p>No persiste nada. El caller ({@code CancelBookingUseCase}) es responsable
 * de guardar el booking cancelado y, si corresponde, disparar el reembolso de
 * crédito mediante {@link CreditDomainService#devolverPorCancelacion} en la
 * misma transacción.</p>
 */
public class CancellationDomainService {

    /**
     * Valida las reglas y construye el {@link Booking} con estado CANCELLED.
     *
     * @param booking  reserva a cancelar (en estado PENDING o CONFIRMED)
     * @param settings configuración del negocio (ventana de horas)
     * @param now      instante actual (inyectado para poder testearlo)
     * @return nueva instancia de Booking con estado CANCELLED y {@code canceladaAt = now}
     * @throws BookingNotCancellableException   si la reserva no está en estado cancelable
     * @throws CancellationNotAllowedException  si el instante actual supera la ventana
     */
    public Booking cancelar(Booking booking, BusinessSettings settings, LocalDateTime now) {
        if (booking.getEstado() != BookingEstado.PENDING
                && booking.getEstado() != BookingEstado.CONFIRMED) {
            throw new BookingNotCancellableException(booking.getId(), booking.getEstado());
        }

        LocalDateTime deadline = booking.getFechaHoraInicio()
                .minusHours(settings.getHoursCancellationLimit());
        if (!now.isBefore(deadline)) {
            throw new CancellationNotAllowedException(
                    booking.getId(), settings.getHoursCancellationLimit());
        }

        return new Booking(
                booking.getId(),
                booking.getBusinessId(),
                booking.getServiceId(),
                booking.getUserId(),
                booking.getSubscriptionId(),
                booking.getStaffMemberId(),
                booking.getFechaHoraInicio(),
                booking.getFechaHoraFin(),
                BookingEstado.CANCELLED,
                booking.getNotas(),
                now,
                booking.getCompletadaAt(),
                booking.getCreatedAt(),
                booking.getUpdatedAt()
        );
    }
}
