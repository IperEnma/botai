package com.botai.application.agenda.usecase.category;

import com.botai.domain.agenda.exception.DuplicateCategorySlugException;
import com.botai.domain.agenda.model.Category;
import com.botai.domain.agenda.repository.CategoryRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Crea una nueva categoría global (platform admin). */
@Service
public class CreateCategoryUseCase {

    private static final Logger log = LoggerFactory.getLogger(CreateCategoryUseCase.class);

    private final CategoryRepository categoryRepository;

    public CreateCategoryUseCase(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    @Transactional
    public Category execute(String nombre, String slug, String icono, List<String> synonyms) {
        if (categoryRepository.existsBySlug(slug)) {
            throw new DuplicateCategorySlugException(slug);
        }
        Category category = new Category(
                UUID.randomUUID(),
                nombre,
                slug,
                icono,
                synonyms == null ? List.of() : synonyms,
                true,
                null,
                null
        );
        Category saved = categoryRepository.save(category);
        log.info("AGENDA: categoría creada slug={} id={}", slug, saved.getId());
        return saved;
    }
}
