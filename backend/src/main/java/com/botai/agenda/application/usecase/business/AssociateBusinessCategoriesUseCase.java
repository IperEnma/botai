package com.botai.agenda.application.usecase.business;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.exception.CategoryNotFoundException;
import com.botai.agenda.domain.model.Category;
import com.botai.agenda.domain.repository.BusinessCategoryRepository;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.CategoryRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Reemplaza las categorías de un negocio por la lista dada.
 *
 * <p>Valida que el negocio pertenezca al tenant y que todas las categorías existan y
 * estén activas antes de aplicar el cambio.</p>
 */
@Service
public class AssociateBusinessCategoriesUseCase {

    private static final Logger log = LoggerFactory.getLogger(AssociateBusinessCategoriesUseCase.class);

    private final BusinessRepository businessRepository;
    private final CategoryRepository categoryRepository;
    private final BusinessCategoryRepository businessCategoryRepository;

    public AssociateBusinessCategoriesUseCase(BusinessRepository businessRepository,
                                              CategoryRepository categoryRepository,
                                              BusinessCategoryRepository businessCategoryRepository) {
        this.businessRepository = businessRepository;
        this.categoryRepository = categoryRepository;
        this.businessCategoryRepository = businessCategoryRepository;
    }

    @Transactional
    public void execute(String tenantId, UUID businessId, List<UUID> categoryIds) {
        if (!businessRepository.existsByIdAndTenantId(businessId, tenantId)) {
            throw new BusinessNotFoundException(businessId);
        }
        if (categoryIds == null) {
            throw new IllegalArgumentException("Lista de categorías requerida");
        }
        for (UUID categoryId : categoryIds) {
            Category category = categoryRepository.findById(categoryId)
                    .orElseThrow(() -> new CategoryNotFoundException(categoryId.toString()));
            if (!category.isActivo()) {
                throw new IllegalArgumentException("La categoría " + category.getSlug() + " no está activa");
            }
        }
        businessCategoryRepository.replaceCategories(businessId, categoryIds);
        log.info("AGENDA: categorías asociadas a negocio id={} count={}", businessId, categoryIds.size());
    }
}
