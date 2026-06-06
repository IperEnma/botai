package com.botai.infrastructure.agenda.persistence.projection;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Proyección JPQL para una fila de {@code agenda_users} con stats agregadas
 * desde {@code agenda_bookings} (y {@code agenda_services} para gasto).
 */
public record ClientStatsRow(
        UUID id,
        String nombre,
        String email,
        String telefono,
        LocalDateTime clienteDesde,
        Long visitas,
        Long inasistencias,
        LocalDateTime ultimaVisita,
        BigDecimal gastoAcumulado
) {}
