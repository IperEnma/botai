package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.Category;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CategoryRepository {

    Category save(Category category);

    Optional<Category> findById(UUID id);

    Optional<Category> findBySlug(String slug);

    List<Category> findAllActive();

    List<Category> findAll();

    boolean existsBySlug(String slug);

    void deleteById(UUID id);
}
