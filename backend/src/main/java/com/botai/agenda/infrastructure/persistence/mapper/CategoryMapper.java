package com.botai.agenda.infrastructure.persistence.mapper;

import com.botai.agenda.domain.model.Category;
import com.botai.agenda.infrastructure.persistence.entity.CategoryEntity;

import java.util.ArrayList;
import java.util.List;

public final class CategoryMapper {

    private CategoryMapper() {
    }

    public static Category toDomain(CategoryEntity entity) {
        if (entity == null) {
            return null;
        }
        List<String> synonyms = entity.getSynonyms() == null ? List.of() : List.copyOf(entity.getSynonyms());
        return new Category(
                entity.getId(),
                entity.getNombre(),
                entity.getSlug(),
                entity.getIcono(),
                synonyms,
                entity.isActivo(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

    public static CategoryEntity toEntity(Category category) {
        if (category == null) {
            return null;
        }
        CategoryEntity entity = new CategoryEntity();
        entity.setId(category.getId());
        entity.setNombre(category.getNombre());
        entity.setSlug(category.getSlug());
        entity.setIcono(category.getIcono());
        entity.setSynonyms(category.getSynonyms() == null ? new ArrayList<>() : new ArrayList<>(category.getSynonyms()));
        entity.setActivo(category.isActivo());
        entity.setCreatedAt(category.getCreatedAt());
        entity.setUpdatedAt(category.getUpdatedAt());
        return entity;
    }
}
