package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.Category;
import com.botai.agenda.domain.repository.CategoryRepository;
import com.botai.agenda.infrastructure.persistence.entity.CategoryEntity;
import com.botai.agenda.infrastructure.persistence.mapper.CategoryMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaCategoryRepository implements CategoryRepository {

    private final CategoryJpaRepository jpa;

    public JpaCategoryRepository(CategoryJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Category save(Category category) {
        CategoryEntity entity = CategoryMapper.toEntity(category);
        if (entity.getId() == null) {
            entity.setId(UUID.randomUUID());
        }
        CategoryEntity saved = jpa.save(entity);
        return CategoryMapper.toDomain(saved);
    }

    @Override
    public Optional<Category> findById(UUID id) {
        return jpa.findById(id).map(CategoryMapper::toDomain);
    }

    @Override
    public Optional<Category> findBySlug(String slug) {
        return jpa.findBySlug(slug).map(CategoryMapper::toDomain);
    }

    @Override
    public List<Category> findAllActive() {
        return jpa.findAllByActivoTrue().stream()
                .map(CategoryMapper::toDomain)
                .toList();
    }

    @Override
    public List<Category> findAll() {
        return jpa.findAll().stream()
                .map(CategoryMapper::toDomain)
                .toList();
    }

    @Override
    public boolean existsBySlug(String slug) {
        return jpa.existsBySlug(slug);
    }

    @Override
    public void deleteById(UUID id) {
        jpa.deleteById(id);
    }
}
