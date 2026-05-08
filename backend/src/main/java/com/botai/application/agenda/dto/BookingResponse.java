package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.BookingEstado;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Vista pública de una {@code Booking}. Incluye los ids relevantes para que el
 * cliente pueda correlacionar con el servicio/suscripción correspondiente.
 */
public record BookingResponse(
        UUID id,
        UUID businessId,
        UUID serviceId,
        UUID userId,
        UUID subscriptionId,
        UUID staffMemberId,
        LocalDateTime fechaHoraInicio,
        LocalDateTime fechaHoraFin,
        BookingEstado estado,
        String notas,
        LocalDateTime canceladaAt,
        LocalDateTime completadaAt,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        // Enriquecimiento para UI (opcional)
        String servicioNombre,
        String clienteNombre,
        String clienteEmail,
        String clienteTelefono
) {
}
