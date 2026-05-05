package com.botai.agenda.domain.model;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests del modelo de dominio {@link Category}.
 *
 * <p>Verificamos dos invariantes:</p>
 * <ul>
 *   <li>El slug no puede ser null (es la clave natural del catálogo).</li>
 *   <li>Los sinónimos se copian defensivamente: mutar la lista original después
 *       de construir la Category no modifica la Category; intentar mutar la lista
 *       expuesta tampoco debe funcionar.</li>
 * </ul>
 */
class CategoryTest {

    @Test
    void rechazaSlugNull() {
        assertThrows(
                NullPointerException.class,
                () -> new Category(
                        UUID.randomUUID(),
                        "Manicure",
                        null,
                        "hand",
                        List.of("uñas", "mani"),
                        true,
                        null, null
                ),
                "El slug no puede ser null"
        );
    }

    @Test
    void rechazaNombreNull() {
        assertThrows(
                NullPointerException.class,
                () -> new Category(
                        UUID.randomUUID(),
                        null,
                        "manicure",
                        null,
                        List.of(),
                        true,
                        null, null
                ),
                "El nombre no puede ser null"
        );
    }

    @Test
    void sinonimosSeCopianDefensivamenteAlConstruir() {
        List<String> original = new ArrayList<>(List.of("uñas", "mani"));

        Category category = new Category(
                UUID.randomUUID(),
                "Manicure",
                "manicure",
                null,
                original,
                true,
                null, null
        );

        original.add("cualquier-cosa-nueva");

        assertEquals(2, category.getSynonyms().size(),
                "Mutar la lista externa no debe afectar la Category");
        assertTrue(category.getSynonyms().contains("uñas"));
        assertTrue(category.getSynonyms().contains("mani"));
    }

    @Test
    void sinonimosExpuestosSonInmutables() {
        Category category = new Category(
                UUID.randomUUID(),
                "Manicure",
                "manicure",
                null,
                List.of("uñas"),
                true,
                null, null
        );

        assertThrows(
                UnsupportedOperationException.class,
                () -> category.getSynonyms().add("algo"),
                "La lista de sinónimos expuesta debe ser inmutable"
        );
    }

    @Test
    void sinonimosNullSeConvierteEnListaVacia() {
        Category category = new Category(
                UUID.randomUUID(),
                "Sin Sinónimos",
                "sin-sinonimos",
                null,
                null,
                true,
                null, null
        );

        assertEquals(0, category.getSynonyms().size(),
                "synonyms null debe traducirse a lista vacía, nunca null");
    }
}
