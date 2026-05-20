package com.botai.domain.agenda.model;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertFalse;

/**
 * Invariantes del domain POJO {@link StaffMember}.
 */
class StaffMemberTest {

    @Test
    void construccionValida_guarda_todosLosCampos() {
        UUID id = UUID.randomUUID();
        UUID businessId = UUID.randomUUID();
        var sm = new StaffMember(id, businessId, "Ana Garcia", "Recepcionista",
                "https://img.url/foto.jpg", null, null, null, null, "ACTIVO", null, null, null, null, null);

        assertEquals(id, sm.getId());
        assertEquals(businessId, sm.getBusinessId());
        assertEquals("Ana Garcia", sm.getNombre());
        assertEquals("Recepcionista", sm.getRol());
        assertEquals("https://img.url/foto.jpg", sm.getAvatarUrl());
        assertEquals("ACTIVO", sm.getStatus());
        assertTrue(sm.isActivo());
        assertNull(sm.getDeletedAt());
    }

    @Test
    void construccionSinBusinessId_lanzaIllegalArgumentException() {
        assertThrows(IllegalArgumentException.class, () ->
                new StaffMember(null, null, "Ana", null, null, null, null, null, null, "ACTIVO", null, null, null, null, null));
    }

    @Test
    void construccionConNombreVacio_lanzaIllegalArgumentException() {
        assertThrows(IllegalArgumentException.class, () ->
                new StaffMember(null, UUID.randomUUID(), "  ", null, null, null, null, null, null, "ACTIVO", null, null, null, null, null));
    }

    @Test
    void construccionConNombreNull_lanzaIllegalArgumentException() {
        assertThrows(IllegalArgumentException.class, () ->
                new StaffMember(null, UUID.randomUUID(), null, null, null, null, null, null, null, "ACTIVO", null, null, null, null, null));
    }

    @Test
    void camposOpcionalesAceptanNull() {
        var sm = new StaffMember(null, UUID.randomUUID(), "Pedro", null, null, null, null, null, null, "ACTIVO", null, null, null, null, null);

        assertNull(sm.getId());
        assertNull(sm.getRol());
        assertNull(sm.getAvatarUrl());
        assertNull(sm.getCustomSchedule());
        assertNull(sm.getCreatedAt());
        assertNull(sm.getUpdatedAt());
    }

    @Test
    void isActivo_derivadoDe_status() {
        UUID bizId = UUID.randomUUID();
        var activo = new StaffMember(null, bizId, "Ana", null, null, null, null, null, null, "ACTIVO", null, null, null, null, null);
        var pausado = new StaffMember(null, bizId, "Ana", null, null, null, null, null, null, "PAUSADO", null, null, null, null, null);
        var archivado = new StaffMember(null, bizId, "Ana", null, null, null, null, null, null, "ARCHIVADO", null, null, null, null, null);

        assertTrue(activo.isActivo());
        assertFalse(pausado.isActivo());
        assertFalse(archivado.isActivo());
    }

    @Test
    void statusNullDefaultsToActivo() {
        var sm = new StaffMember(null, UUID.randomUUID(), "Ana", null, null, null, null, null, null, null, null, null, null, null, null);
        assertEquals("ACTIVO", sm.getStatus());
        assertTrue(sm.isActivo());
    }
}
