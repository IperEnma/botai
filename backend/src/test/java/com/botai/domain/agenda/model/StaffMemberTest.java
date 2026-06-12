package com.botai.domain.agenda.model;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertFalse;

class StaffMemberTest {

    @Test
    void construccionValida_guarda_todosLosCampos() {
        UUID id = UUID.randomUUID();
        UUID businessId = UUID.randomUUID();
        var sm = StaffMember.builder()
                .id(id)
                .businessId(businessId)
                .nombre("Ana Garcia")
                .rol("Recepcionista")
                .avatarUrl("https://img.url/foto.jpg")
                .status("ACTIVO")
                .build();

        assertEquals(id, sm.getId());
        assertTrue(sm.belongsTo(businessId));
        assertEquals(1, sm.getBusinessIds().size());
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
                StaffMember.builder().nombre("Ana").build());
    }

    @Test
    void construccionConNombreVacio_lanzaIllegalArgumentException() {
        assertThrows(IllegalArgumentException.class, () ->
                StaffMember.builder().businessId(UUID.randomUUID()).nombre("  ").build());
    }

    @Test
    void construccionConNombreNull_lanzaIllegalArgumentException() {
        assertThrows(IllegalArgumentException.class, () ->
                StaffMember.builder().businessId(UUID.randomUUID()).build());
    }

    @Test
    void camposOpcionalesAceptanNull() {
        var sm = StaffMember.builder()
                .businessId(UUID.randomUUID())
                .nombre("Pedro")
                .build();

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
        var activo    = StaffMember.builder().businessId(bizId).nombre("Ana").status("ACTIVO").build();
        var pausado   = StaffMember.builder().businessId(bizId).nombre("Ana").status("PAUSADO").build();
        var archivado = StaffMember.builder().businessId(bizId).nombre("Ana").status("ARCHIVADO").build();

        assertTrue(activo.isActivo());
        assertFalse(pausado.isActivo());
        assertFalse(archivado.isActivo());
    }

    @Test
    void statusNullDefaultsToActivo() {
        var sm = StaffMember.builder()
                .businessId(UUID.randomUUID())
                .nombre("Ana")
                .build();

        assertEquals("ACTIVO", sm.getStatus());
        assertTrue(sm.isActivo());
    }
}
