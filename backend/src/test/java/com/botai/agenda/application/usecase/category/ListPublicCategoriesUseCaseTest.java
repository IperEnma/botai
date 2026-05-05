package com.botai.agenda.application.usecase.category;

import com.botai.agenda.domain.model.Category;
import com.botai.agenda.domain.repository.CategoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ListPublicCategoriesUseCaseTest {

    private CategoryRepository categoryRepository;
    private ListPublicCategoriesUseCase useCase;

    @BeforeEach
    void setUp() {
        categoryRepository = mock(CategoryRepository.class);
        useCase = new ListPublicCategoriesUseCase(categoryRepository);
    }

    private Category cat(String slug, boolean activo) {
        return new Category(UUID.randomUUID(), slug, slug, null, List.of(), activo,
                LocalDateTime.now(), LocalDateTime.now());
    }

    @Test
    void listActiveDelegaAlPuertoFindAllActive() {
        List<Category> expected = List.of(cat("yoga", true), cat("manicure", true));
        when(categoryRepository.findAllActive()).thenReturn(expected);

        List<Category> result = useCase.listActive();

        assertSame(expected, result);
        verify(categoryRepository).findAllActive();
    }

    @Test
    void listAllDelegaAlPuertoFindAll() {
        List<Category> expected = List.of(cat("yoga", true), cat("vieja", false));
        when(categoryRepository.findAll()).thenReturn(expected);

        List<Category> result = useCase.listAll();

        assertEquals(2, result.size());
        verify(categoryRepository).findAll();
    }
}
