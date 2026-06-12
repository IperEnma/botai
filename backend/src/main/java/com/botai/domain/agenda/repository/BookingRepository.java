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
     */
    List<Booking> findOverlapping(UUID businessId,
                                  UUID serviceId,
                                  LocalDateTime desde,
                                  LocalDateTime hasta);

    /**
     * Reservas activas (PENDING / CONFIRMED) del profesional cuyo intervalo
     * {@code [fechaHoraInicio, fechaHoraFin)} se solapa con el slot pedido.
     *
     * <p><b>Scope tenant, no por sucursal.</b> Un staff puede pertenecer a varias
     * sucursales pero su agenda es única dentro del tenant: la regla de
     * no-solapamiento aplica sobre <em>todas</em> sus reservas, sin importar
     * en qué sucursal estén tomadas.</p>
     */
    List<Booking> findOverlappingForStaff(UUID staffMemberId,
                                          LocalDateTime desde,
                                          LocalDateTime hasta);

    List<Booking> findAllByUserId(UUID userId);

    List<Booking> findAllByUserIdAndEstado(UUID userId, BookingEstado estado);

    List<Booking> findAllByBusinessIdAndFecha(UUID businessId,
                                              LocalDateTime desde,
                                              LocalDateTime hasta);

    /**
     * Mismo rango y negocio que {@link #findAllByBusinessIdAndFecha}, pero
     * acota al {@code staffMemberId} indicado. Usado por el listado del panel
     * cuando el caller es STAFF (operator/viewer) para devolver solo sus
     * propias reservas y nunca filtrar las de otros profesionales.
     */
    List<Booking> findAllByBusinessIdAndStaffMemberIdAndFecha(UUID businessId,
                                                              UUID staffMemberId,
                                                              LocalDateTime desde,
                                                              LocalDateTime hasta);

    /**
     * Cuenta reservas CONFIRMED o COMPLETED de un usuario en un negocio
     * cuya {@code fechaHoraInicio} es igual o posterior a {@code desde}.
     * Usado por el motor de fidelización para evaluar el umbral de asistencias.
     */
    int countConfirmedInWindow(UUID userId, UUID businessId, LocalDateTime desde);
}
