package com.botai.domain.agenda.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Cliente del tenant junto con estadísticas agregadas a partir de sus bookings:
 * visitas (estado COMPLETED), inasistencias (NO_SHOW), última visita y gasto
 * acumulado (suma de precio del servicio asociado a cada booking COMPLETED).
 */
public record ClientWithStats(
        UUID id,
        String nombre,
        String email,
        String telefono,
        LocalDateTime clienteDesde,
        long visitas,
        long inasistencias,
        LocalDateTime ultimaVisita,
        BigDecimal gastoAcumulado
) {}
