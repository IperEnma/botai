package com.botai.domain.agenda.model;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

/**
 * Tests unitarios del modelo de dominio {@link Service}.
 *
 * <p>La regla de negocio que se valida es que un servicio no puede tener
 * {@code duracionMin <= 0} — un servicio de 0 minutos no tiene sentido.</p>
 */
class ServiceTest {

    private static final UUID BUSINESS_ID = UUID.randomUUID();

    @Test
    void rechazaDuracionCero() {
        IllegalArgumentException ex = assertThrows(
                IllegalArgumentException.class,
                () -> new Service(
                        UUID.randomUUID(),
                        BUSINESS_ID,
                        "Corte",
                        "Corte básico",
                        0,
                        new BigDecimal("100.00"),
                        true,
                        ServiceSchedulingMode.GENERAL,
                        null,
                        null,
                        null
                ),
                "Un servicio no puede tener duración cero"
        );
        assertEquals("duracionMin debe ser positivo", ex.getMessage());
    }

    @Test
    void rechazaDuracionNegativa() {
        assertThrows(
                IllegalArgumentException.class,
                () -> new Service(
                        UUID.randomUUID(),
                        BUSINESS_ID,
                        "Corte",
                        null,
                        -5,
                        BigDecimal.ZERO,
                        true,
                        ServiceSchedulingMode.GENERAL,
                        null,
                        null,
                        null
                ),
                "Un servicio no puede tener duración negativa"
        );
    }

    @Test
    void aceptaDuracionPositiva() {
        Service service = new Service(
                UUID.randomUUID(),
                BUSINESS_ID,
                "Manicura",
                "Básica",
                45,
                new BigDecimal("2500.00"),
                true,
                ServiceSchedulingMode.GENERAL,
                null,
                null,
                null
        );
        assertEquals(45, service.getDuracionMin());
        assertEquals(BUSINESS_ID, service.getBusinessId());
    }
}
