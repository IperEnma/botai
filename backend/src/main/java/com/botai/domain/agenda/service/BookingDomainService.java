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
     * Verifica (RF06) que el slot pedido no se solape con otra reserva activa
     * del mismo negocio y servicio. Si hay solapamiento → excepción.
     *
     * <p><b>Nota:</b> esta verificación es best-effort sin bloqueo: dos
     * requests podrían pasar el check y luego ambos insertar. En Slice 1
     * aceptamos ese race window porque el flujo real pasa por
     * {@code CreateBookingUseCase}, que ya corre dentro de una tx con lock
     * sobre la suscripción — si hay concurrencia la ganadora inserta y la
     * perdedora va a fallar por índice único o por lock timeout en Sprints
     * siguientes (cuando introduzcamos bloqueo por recurso/slot).</p>
     */
    public void validarDisponibilidad(UUID businessId,
                                      UUID serviceId,
                                      LocalDateTime desde,
                                      LocalDateTime hasta) {
        List<Booking> overlap = bookingRepository.findOverlapping(businessId, serviceId, desde, hasta);
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
