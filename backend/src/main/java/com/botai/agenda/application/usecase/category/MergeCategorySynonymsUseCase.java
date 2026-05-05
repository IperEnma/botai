package com.botai.agenda.application.usecase.category;

import com.botai.agenda.domain.exception.CategoryNotFoundException;
import com.botai.agenda.domain.model.Category;
import com.botai.agenda.domain.repository.CategoryRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/** Agrega sinónimos a una categoría (unión de conjuntos, preserva orden). */
@Service
public class MergeCategorySynonymsUseCase {

    private static final Logger log = LoggerFactory.getLogger(MergeCategorySynonymsUseCase.class);

    private final CategoryRepository categoryRepository;

    public MergeCategorySynonymsUseCase(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    @Transactional
    public Category execute(UUID id, List<String> newSynonyms) {
        Category existing = categoryRepository.findById(id)
                .orElseThrow(() -> new CategoryNotFoundException(id.toString()));

        Set<String> merged = new LinkedHashSet<>(existing.getSynonyms());
        if (newSynonyms != null) {
            for (String s : newSynonyms) {
                if (s != null && !s.isBlank()) {
                    merged.add(s.trim());
                }
            }
        }

        Category updated = new Category(
                existing.getId(),
                existing.getNombre(),
                existing.getSlug(),
                existing.getIcono(),
                List.copyOf(merged),
                existing.isActivo(),
                existing.getCreatedAt(),
                existing.getUpdatedAt()
        );
        Category saved = categoryRepository.save(updated);
        log.info("AGENDA: sinónimos fusionados en categoría id={} total={}", id, merged.size());
        return saved;
    }
}
