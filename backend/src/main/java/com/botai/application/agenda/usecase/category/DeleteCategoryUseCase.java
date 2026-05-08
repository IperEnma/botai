package com.botai.application.agenda.usecase.category;

import com.botai.domain.agenda.exception.CategoryNotFoundException;
import com.botai.domain.agenda.repository.CategoryRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Borra una categoría del catálogo global.
 *
 * <p>Comportamiento de Sprint 1: se intenta un hard delete. Si la BD rechaza por
 * {@code ON DELETE RESTRICT} de {@code agenda_business_categories}, lanzamos
 * {@link IllegalStateException} con mensaje claro — la UI debería pedir al admin
 * que primero desvincule los negocios asociados.</p>
 */
@Service
public class DeleteCategoryUseCase {

    private static final Logger log = LoggerFactory.getLogger(DeleteCategoryUseCase.class);

    private final CategoryRepository categoryRepository;

    public DeleteCategoryUseCase(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    @Transactional
    public void execute(UUID id) {
        if (categoryRepository.findById(id).isEmpty()) {
            throw new CategoryNotFoundException(id.toString());
        }
        try {
            categoryRepository.deleteById(id);
            log.info("AGENDA: categoría eliminada id={}", id);
        } catch (DataIntegrityViolationException ex) {
            log.warn("AGENDA: no se pudo eliminar categoría id={}: {}", id, ex.getMessage());
            throw new IllegalStateException(
                    "No se puede eliminar la categoría porque tiene negocios asociados.", ex);
        }
    }
}
