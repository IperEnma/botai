package com.botai.application.agenda.usecase.category;

import com.botai.domain.agenda.exception.CategoryNotFoundException;
import com.botai.domain.agenda.model.Category;
import com.botai.domain.agenda.repository.CategoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UpdateCategoryUseCaseTest {

    private CategoryRepository categoryRepository;
    private UpdateCategoryUseCase useCase;

    private final UUID categoryId = UUID.randomUUID();
    private final LocalDateTime created = LocalDateTime.of(2026, 1, 1, 9, 0);
    private final LocalDateTime updated = LocalDateTime.of(2026, 1, 2, 9, 0);

    @BeforeEach
    void setUp() {
        categoryRepository = mock(CategoryRepository.class);
        useCase = new UpdateCategoryUseCase(categoryRepository);
    }

    private Category existing() {
        return new Category(
                categoryId, "Manicure", "manicure", "hand",
                List.of("uñas", "mani"), true, created, updated);
    }

    @Test
    void actualizaNombreYSinonimosSinCambiarSlug() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(existing()));
        when(categoryRepository.save(any(Category.class))).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(categoryId, "Manicure & Pedicure", null,
                List.of("uñas", "mani", "pedi"), null);

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepository).save(captor.capture());
        Category saved = captor.getValue();

        assertEquals("Manicure & Pedicure", saved.getNombre());
        assertEquals("manicure", saved.getSlug(), "El slug es inmutable");
        assertEquals("hand", saved.getIcono());
        assertEquals(3, saved.getSynonyms().size());
    }

    @Test
    void puedeDesactivarLaCategoria() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(existing()));
        when(categoryRepository.save(any(Category.class))).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(categoryId, null, null, null, false);

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepository).save(captor.capture());
        assertFalse(captor.getValue().isActivo());
    }

    @Test
    void siNoExisteLanzaCategoryNotFound() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThrows(CategoryNotFoundException.class,
                () -> useCase.execute(categoryId, "X", null, null, null));

        verify(categoryRepository, never()).save(any(Category.class));
    }
}
