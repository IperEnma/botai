package com.botai.agenda.application.mapper;

import com.botai.agenda.application.dto.CategoryResponse;
import com.botai.agenda.domain.model.Category;

public final class CategoryDtoMapper {

    private CategoryDtoMapper() {
    }

    public static CategoryResponse toResponse(Category category) {
        if (category == null) {
            return null;
        }
        return new CategoryResponse(
                category.getId(),
                category.getNombre(),
                category.getSlug(),
                category.getIcono(),
                category.getSynonyms(),
                category.isActivo()
        );
    }
}
