package com.botai.application.agenda.mapper;

import com.botai.application.agenda.dto.CategoryResponse;
import com.botai.domain.agenda.model.Category;

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
