package com.botai.domain.agenda.repository;

import java.util.List;
import java.util.UUID;

public interface BusinessCategoryRepository {

    void associate(UUID businessId, UUID categoryId);

    void replaceCategories(UUID businessId, List<UUID> categoryIds);

    List<UUID> findCategoryIdsByBusinessId(UUID businessId);

    List<String> findCategorySlugsByBusinessId(UUID businessId);

    List<UUID> findBusinessIdsByCategoryId(UUID categoryId);
}
