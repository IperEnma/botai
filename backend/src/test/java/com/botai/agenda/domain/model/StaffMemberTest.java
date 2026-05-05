package com.botai.agenda.domain.model;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Invariantes del domain POJO {@link StaffMember}.
 */
class StaffMemberTest {

    @Test
    void construccionValida_guarda_todosLosCampos() {
        UUID id = UUID.randomUUID();
        UUID businessId = UUID.randomUUID();
        var sm = new StaffMember(id, businessId, "Ana Garcia", "Recepcionista",
                "https://img.url/foto.jpg", true, null, null, null);

        assertEquals(id, sm.getId());
        assertEquals(businessId, sm.getBusinessId());
        assertEquals("Ana Garcia", sm.getNombre());
        assertEquals("Recepcionista", sm.getRol());
        assertEquals("https://img.url/foto.jpg", sm.getAvatarUrl());
        assertTrue(sm.isActivo());
        assertNull(sm.getDeletedAt());
    }

    @Test
    void construccionSinBusinessId_lanzaIllegalArgumentException() {
        assertThrows(IllegalArgumentException.class, () ->
                new StaffMember(null, null, "Ana", null, null, true, null, null, null));
    }

    @Test
    void construccionConNombreVacio_lanzaIllegalArgumentException() {
        assertThrows(IllegalArgumentException.class, () ->
                new StaffMember(null, UUID.randomUUID(), "  ", null, null, true, null, null, null));
    }

    @Test
    void construccionConNombreNull_lanzaIllegalArgumentException() {
        assertThrows(IllegalArgumentException.class, () ->
                new StaffMember(null, UUID.randomUUID(), null, null, null, true, null, null, null));
    }

    @Test
    void camposOpcionalesAceptanNull() {
        var sm = new StaffMember(null, UUID.randomUUID(), "Pedro", null, null, true, null, null, null);

        assertNull(sm.getId());
        assertNull(sm.getRol());
        assertNull(sm.getAvatarUrl());
        assertNull(sm.getCreatedAt());
        assertNull(sm.getUpdatedAt());
    }
}
