package com.botai.agenda.application.usecase.category;

import com.botai.agenda.domain.exception.DuplicateCategorySlugException;
import com.botai.agenda.domain.model.Category;
import com.botai.agenda.domain.repository.CategoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CreateCategoryUseCaseTest {

    private CategoryRepository categoryRepo;
    private CreateCategoryUseCase useCase;

    @BeforeEach
    void setUp() {
        categoryRepo = mock(CategoryRepository.class);
        useCase = new CreateCategoryUseCase(categoryRepo);
    }

    @Test
    void creaCategoriaConSlugUnico() {
        when(categoryRepo.existsBySlug("manicure")).thenReturn(false);
        when(categoryRepo.save(any(Category.class))).thenAnswer(inv -> inv.getArgument(0));

        Category result = useCase.execute("Manicure", "manicure", "hand", List.of("uñas", "mani"));

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepo).save(captor.capture());
        Category saved = captor.getValue();

        assertNotNull(saved.getId(), "La categoría creada debe tener un ID generado");
        assertEquals("manicure", saved.getSlug());
        assertEquals("Manicure", saved.getNombre());
        assertTrue(saved.isActivo(), "Una categoría recién creada debe estar activa");
        assertEquals(2, saved.getSynonyms().size());
        assertEquals(saved.getId(), result.getId());
    }

    @Test
    void rechazaSlugDuplicado() {
        when(categoryRepo.existsBySlug("manicure")).thenReturn(true);

        DuplicateCategorySlugException ex = assertThrows(
                DuplicateCategorySlugException.class,
                () -> useCase.execute("Manicure", "manicure", null, List.of()),
                "Un slug ya existente debe rechazarse con DuplicateCategorySlugException"
        );
        assertTrue(ex.getMessage().contains("manicure"),
                "El mensaje de error debe mencionar el slug duplicado");

        verify(categoryRepo, never()).save(any(Category.class));
    }

    @Test
    void synonymsNullSeTraducenEnListaVacia() {
        when(categoryRepo.existsBySlug("yoga")).thenReturn(false);
        when(categoryRepo.save(any(Category.class))).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute("Yoga", "yoga", null, null);

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepo).save(captor.capture());
        assertEquals(0, captor.getValue().getSynonyms().size());
    }

    @Test
    void generaUuidDistintoParaCadaCategoria() {
        when(categoryRepo.existsBySlug(any())).thenReturn(false);
        when(categoryRepo.save(any(Category.class))).thenAnswer(inv -> inv.getArgument(0));

        Category a = useCase.execute("A", "a", null, null);
        Category b = useCase.execute("B", "b", null, null);

        UUID idA = a.getId();
        UUID idB = b.getId();
        assertNotNull(idA);
        assertNotNull(idB);
        assertTrue(!idA.equals(idB), "Dos categorías distintas deben tener UUIDs distintos");
    }
}
