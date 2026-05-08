package com.botai.domain.agenda.model;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

/**
 * Tests del agregado {@link Business}: invariantes básicas del constructor.
 */
class BusinessTest {

    @Test
    void rechazaTenantIdNull() {
        assertThrows(
                NullPointerException.class,
                () -> new Business(
                        UUID.randomUUID(),
                        null,
                        "Peluquería Centro",
                        "Una pelu",
                        null,
                        List.of(),
                        true,
                        null, null, null, null, null, null, null, null, null, null
                ),
                "El tenantId no puede ser null"
        );
    }

    @Test
    void rechazaNombreNull() {
        assertThrows(
                NullPointerException.class,
                () -> new Business(
                        UUID.randomUUID(),
                        "tenant-1",
                        null,
                        null,
                        null,
                        List.of(),
                        true,
                        null, null, null, null, null, null, null, null, null, null
                ),
                "El nombre del negocio no puede ser null"
        );
    }

    @Test
    void searchTagsNullSeConvierteEnListaVacia() {
        Business business = new Business(
                UUID.randomUUID(),
                "tenant-1",
                "Test",
                null,
                null,
                null,
                true,
                null, null, null, null, null, null, null, null, null, null
        );

        assertNotNull(business.getSearchTags(), "searchTags nunca debería ser null");
        assertEquals(0, business.getSearchTags().size(),
                "searchTags null se traduce a lista vacía");
    }
}
