package com.botai.domain.agenda.service;

import com.botai.domain.agenda.exception.BookingSlotTakenException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.repository.BookingRepository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Reglas de dominio para construir una reserva confirmada.
 *
 * <p>Igual que {@code CreditDomainService}, este servicio no bloquea ni
 * persiste directamente la suscripción: asume que el caller ya tomó el lock
 * sobre el recurso crítico y delega acá la verificación de disponibilidad y
 * el ensamblado del objeto {@link Booking} con estado {@code CONFIRMED}.</p>
 */
public class BookingDomainService {

    private final BookingRepository bookingRepository;

    public BookingDomainService(BookingRepository bookingRepository) {
        this.bookingRepository = bookingRepository;
    }

    /**
     * Regla de no-solapamiento global por profesional: la agenda de un
     * {@code StaffMember} es <strong>única dentro del tenant</strong>. Aunque
     * pertenezca a varias sucursales, no puede tener dos reservas activas
     * solapadas, independientemente del business en que se hayan tomado.
     *
     * <p>La verificación de aplicación es best-effort (race window posible);
     * el {@code EXCLUDE GiST} en {@code excl_agenda_bookings_staff_slot} (V5)
     * cierra ese hueco a nivel base.</p>
     */
    public void validarDisponibilidad(UUID staffMemberId,
                                      LocalDateTime desde,
                                      LocalDateTime hasta) {
        if (staffMemberId == null) return;
        List<Booking> overlap = bookingRepository.findOverlappingForStaff(staffMemberId, desde, hasta);
        if (!overlap.isEmpty()) {
            throw new BookingSlotTakenException();
        }
    }

    /**
     * Construye una {@link Booking} con estado {@code CONFIRMED} lista para
     * ser persistida. Atención: acá NO se descuenta crédito — eso lo hace
     * el {@code CreditDomainService} y lo orquesta el use case en la misma
     * transacción.
     */
    public Booking construirConfirmada(UUID businessId,
                                       UUID serviceId,
                                       UUID userId,
                                       UUID subscriptionId,
                                       UUID staffMemberId,
                                       LocalDateTime desde,
                                       LocalDateTime hasta,
                                       String notas) {
        return new Booking(
                null, businessId, serviceId, userId, subscriptionId, staffMemberId,
                desde, hasta,
                BookingEstado.CONFIRMED,
                notas,
                null, null, null, null
        );
    }
}
