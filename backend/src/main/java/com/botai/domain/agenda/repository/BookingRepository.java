package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Puerto de persistencia para {@link Booking}.
 */
public interface BookingRepository {

    Booking save(Booking booking);

    Optional<Booking> findById(UUID id);

    /**
     * Reservas activas (PENDING / CONFIRMED) del mismo negocio y servicio cuyo
     * intervalo [fechaHoraInicio, fechaHoraFin) se solapa con el slot pedido.
     * Se usa en {@code BookingDomainService.validarDisponibilidad}.
     */
    List<Booking> findOverlapping(UUID businessId,
                                  UUID serviceId,
                                  LocalDateTime desde,
                                  LocalDateTime hasta);

    List<Booking> findAllByUserId(UUID userId);

    List<Booking> findAllByUserIdAndEstado(UUID userId, BookingEstado estado);

    List<Booking> findAllByBusinessIdAndFecha(UUID businessId,
                                              LocalDateTime desde,
                                              LocalDateTime hasta);

    /**
     * Cuenta reservas CONFIRMED o COMPLETED de un usuario en un negocio
     * cuya {@code fechaHoraInicio} es igual o posterior a {@code desde}.
     * Usado por el motor de fidelización para evaluar el umbral de asistencias.
     */
    int countConfirmedInWindow(UUID userId, UUID businessId, LocalDateTime desde);
}
