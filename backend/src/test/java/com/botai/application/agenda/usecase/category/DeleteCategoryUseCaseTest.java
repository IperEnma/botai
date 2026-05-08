package com.botai.application.agenda.usecase.category;

import com.botai.domain.agenda.exception.CategoryNotFoundException;
import com.botai.domain.agenda.model.Category;
import com.botai.domain.agenda.repository.CategoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DeleteCategoryUseCaseTest {

    private CategoryRepository categoryRepository;
    private DeleteCategoryUseCase useCase;

    private final UUID categoryId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        categoryRepository = mock(CategoryRepository.class);
        useCase = new DeleteCategoryUseCase(categoryRepository);
    }

    private Category existing() {
        return new Category(categoryId, "Yoga", "yoga", null, List.of(), true,
                LocalDateTime.now(), LocalDateTime.now());
    }

    @Test
    void borraCategoriaSiExisteYNoHayFK() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(existing()));
        doNothing().when(categoryRepository).deleteById(categoryId);

        useCase.execute(categoryId);

        verify(categoryRepository).deleteById(categoryId);
    }

    @Test
    void siNoExisteLanzaCategoryNotFound() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThrows(CategoryNotFoundException.class, () -> useCase.execute(categoryId));

        verify(categoryRepository, never()).deleteById(categoryId);
    }

    @Test
    void siTieneNegociosAsociadosLanzaIllegalStateConMensajeClaro() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(existing()));
        doThrow(new DataIntegrityViolationException("FK agenda_business_categories"))
                .when(categoryRepository).deleteById(categoryId);

        IllegalStateException ex = assertThrows(IllegalStateException.class,
                () -> useCase.execute(categoryId));

        assertTrue(ex.getMessage().toLowerCase().contains("negocios"),
                "El mensaje debe explicar que hay negocios asociados: " + ex.getMessage());
        assertEquals(DataIntegrityViolationException.class, ex.getCause().getClass());
    }
}
