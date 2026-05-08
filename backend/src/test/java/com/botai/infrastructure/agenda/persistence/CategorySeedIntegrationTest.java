package com.botai.infrastructure.agenda.persistence;

import com.botai.AbstractAgendaIntegrationTest;
import com.botai.infrastructure.agenda.persistence.entity.CategoryEntity;
import com.botai.infrastructure.agenda.persistence.jpa.CategoryJpaRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Valida que la migración {@code V2__agenda_seed_categories.sql} dejó el
 * catálogo global con las 10 categorías esperadas y con sus sinónimos
 * maestros.
 */
class CategorySeedIntegrationTest extends AbstractAgendaIntegrationTest {

    private static final List<String> SLUGS_ESPERADOS = List.of(
            "peluqueria", "barberia", "manicure", "pedicure",
            "spa", "yoga", "gimnasio", "tatuajes",
            "masajes", "estetica"
    );

    @Autowired
    private CategoryJpaRepository categoryRepo;

    @Test
    void seedCrea10CategoriasConSlugsEsperados() {
        List<CategoryEntity> all = categoryRepo.findAll();

        assertTrue(all.size() >= 10,
                "El seed debe dejar al menos 10 categorías activas (hay " + all.size() + ")");

        Set<String> slugs = all.stream()
                .map(CategoryEntity::getSlug)
                .collect(Collectors.toSet());

        for (String slug : SLUGS_ESPERADOS) {
            assertTrue(slugs.contains(slug),
                    "El seed debe contener la categoría con slug=" + slug);
        }
    }

    @Test
    void categoriaManicureTieneSinonimosEspanoles() {
        Optional<CategoryEntity> manicure = categoryRepo.findBySlug("manicure");

        assertTrue(manicure.isPresent(), "Debe existir la categoría 'manicure'");
        List<String> synonyms = manicure.get().getSynonyms();
        assertTrue(synonyms.contains("uñas"),
                "Los sinónimos de 'manicure' deben incluir 'uñas'");
        assertTrue(synonyms.contains("mani"),
                "Los sinónimos de 'manicure' deben incluir 'mani'");
    }

    @Test
    void todasLasCategoriasDelSeedEstanActivas() {
        List<CategoryEntity> active = categoryRepo.findAllByActivoTrue();
        Set<String> activeSlugs = active.stream()
                .map(CategoryEntity::getSlug)
                .collect(Collectors.toSet());

        for (String slug : SLUGS_ESPERADOS) {
            assertTrue(activeSlugs.contains(slug),
                    "La categoría del seed '" + slug + "' debe estar activa");
        }
    }
}
