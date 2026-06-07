package com.botai.application.agenda.support;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class BusinessAddressSupportTest {

    @Test
    void blankSeNormalizaComoNull() {
        assertNull(BusinessAddressSupport.normalizeOrNull(null));
        assertNull(BusinessAddressSupport.normalizeOrNull("   "));
    }

    @Test
    void aceptaDireccionBarrioOCiudad() {
        assertEquals("Pocitos, Montevideo", BusinessAddressSupport.normalizeOrNull("  Pocitos, Montevideo  "));
        assertEquals("Av. Brasil 2847", BusinessAddressSupport.normalizeOrNull("Av. Brasil 2847"));
    }

    @Test
    void rechazaUrlYUploads() {
        assertThrows(IllegalArgumentException.class,
                () -> BusinessAddressSupport.normalizeOrNull("https://maps.google.com/foo"));
        assertThrows(IllegalArgumentException.class,
                () -> BusinessAddressSupport.normalizeOrNull("/uploads/businesses/x/addr.txt"));
    }

    @Test
    void rechazaTextoSinLetrasOCorto() {
        assertThrows(IllegalArgumentException.class,
                () -> BusinessAddressSupport.normalizeOrNull("12"));
        assertThrows(IllegalArgumentException.class,
                () -> BusinessAddressSupport.normalizeOrNull("AB"));
    }
}
