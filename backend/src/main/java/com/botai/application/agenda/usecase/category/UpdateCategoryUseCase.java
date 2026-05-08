package com.botai.application.agenda.usecase.category;

import com.botai.domain.agenda.exception.CategoryNotFoundException;
import com.botai.domain.agenda.model.Category;
import com.botai.domain.agenda.repository.CategoryRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Actualiza una categoría existente (platform admin). */
@Service
public class UpdateCategoryUseCase {

    private static final Logger log = LoggerFactory.getLogger(UpdateCategoryUseCase.class);

    private final CategoryRepository categoryRepository;

    public UpdateCategoryUseCase(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    @Transactional
    public Category execute(UUID id,
                            String nombre,
                            String icono,
                            List<String> synonyms,
                            Boolean activo) {
        Category existing = categoryRepository.findById(id)
                .orElseThrow(() -> new CategoryNotFoundException(id.toString()));

        Category updated = new Category(
                existing.getId(),
                nombre == null ? existing.getNombre() : nombre,
                existing.getSlug(), // slug es inmutable (estable para URLs)
                icono == null ? existing.getIcono() : icono,
                synonyms == null ? existing.getSynonyms() : synonyms,
                activo == null ? existing.isActivo() : activo,
                existing.getCreatedAt(),
                existing.getUpdatedAt()
        );
        Category saved = categoryRepository.save(updated);
        log.info("AGENDA: categoría actualizada id={}", id);
        return saved;
    }
}
