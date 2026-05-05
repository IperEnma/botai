package com.botai.agenda.application.usecase.category;

import com.botai.agenda.domain.exception.CategoryNotFoundException;
import com.botai.agenda.domain.model.Category;
import com.botai.agenda.domain.repository.CategoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;

/**
 * Tests del merge de sinónimos.
 *
 * <p><b>Observación sobre la normalización:</b> el use case actual
 * hace {@code trim()} a los valores entrantes pero NO los convierte a
 * lowercase antes de comparar. Por lo tanto "Uñas" y "uñas" hoy se
 * considerarían distintos. Los tests reflejan el comportamiento real;
 * ver reporte final para la recomendación.</p>
 */
class MergeCategorySynonymsUseCaseTest {

    private CategoryRepository categoryRepo;
    private MergeCategorySynonymsUseCase useCase;

    private static final UUID ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        categoryRepo = mock(CategoryRepository.class);
        useCase = new MergeCategorySynonymsUseCase(categoryRepo);
    }

    @Test
    void fusionaSinonimosUnionSinDuplicados() {
        Category existing = new Category(
                ID, "Manicure", "manicure", null,
                List.of("uñas", "mani"),
                true, null, null
        );
        when(categoryRepo.findById(ID)).thenReturn(Optional.of(existing));
        when(categoryRepo.save(any(Category.class))).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(ID, List.of("mani", "uñitas", "nail"));

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepo).save(captor.capture());
        List<String> saved = captor.getValue().getSynonyms();

        // El merge debe contener los 4 distintos: uñas, mani, uñitas, nail
        assertEquals(4, saved.size(),
                "El merge debe eliminar duplicados exactos");
        assertTrue(saved.containsAll(Arrays.asList("uñas", "mani", "uñitas", "nail")));
    }

    @Test
    void ignoraSinonimosNullOBlanco() {
        Category existing = new Category(
                ID, "Spa", "spa", null,
                List.of("spa"),
                true, null, null
        );
        when(categoryRepo.findById(ID)).thenReturn(Optional.of(existing));
        when(categoryRepo.save(any(Category.class))).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(ID, Arrays.asList(null, "  ", "relax"));

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepo).save(captor.capture());
        List<String> saved = captor.getValue().getSynonyms();

        assertEquals(2, saved.size());
        assertTrue(saved.contains("spa"));
        assertTrue(saved.contains("relax"));
    }

    @Test
    void aplicaTrimALosSinonimosEntrantes() {
        Category existing = new Category(
                ID, "Yoga", "yoga", null,
                List.of("yoga"),
                true, null, null
        );
        when(categoryRepo.findById(ID)).thenReturn(Optional.of(existing));
        when(categoryRepo.save(any(Category.class))).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(ID, List.of("  pilates  "));

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepo).save(captor.capture());
        List<String> saved = captor.getValue().getSynonyms();

        assertTrue(saved.contains("pilates"),
                "El use case debe hacer trim de los sinónimos entrantes");
    }

    @Test
    void lanzaCategoryNotFoundSiLaCategoriaNoExiste() {
        when(categoryRepo.findById(ID)).thenReturn(Optional.empty());

        assertThrows(
                CategoryNotFoundException.class,
                () -> useCase.execute(ID, List.of("algo"))
        );
    }

    @Test
    void sinonimosEntrantesNullConservaLosExistentes() {
        Category existing = new Category(
                ID, "Gym", "gimnasio", null,
                List.of("gym", "fitness"),
                true, null, null
        );
        when(categoryRepo.findById(ID)).thenReturn(Optional.of(existing));
        when(categoryRepo.save(any(Category.class))).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(ID, null);

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepo).save(captor.capture());
        assertEquals(2, captor.getValue().getSynonyms().size(),
                "Si la lista nueva es null, los sinónimos existentes se conservan");
    }
}
