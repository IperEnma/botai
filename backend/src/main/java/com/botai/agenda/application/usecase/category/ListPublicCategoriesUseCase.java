package com.botai.agenda.application.usecase.category;

import com.botai.agenda.domain.model.Category;
import com.botai.agenda.domain.repository.CategoryRepository;
import com.botai.agenda.infrastructure.config.AgendaCacheConfig;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Devuelve el catálogo global de categorías. */
@Service
public class ListPublicCategoriesUseCase {

    private final CategoryRepository categoryRepository;

    public ListPublicCategoriesUseCase(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    @Cacheable(cacheManager = "agendaCacheManager", value = AgendaCacheConfig.CACHE_CATEGORIES)
    @Transactional(readOnly = true)
    public List<Category> listActive() {
        return categoryRepository.findAllActive();
    }

    @Transactional(readOnly = true)
    public List<Category> listAll() {
        return categoryRepository.findAll();
    }
}
