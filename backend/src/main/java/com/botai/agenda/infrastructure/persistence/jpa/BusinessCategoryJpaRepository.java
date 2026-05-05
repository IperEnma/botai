package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.infrastructure.persistence.entity.BusinessCategoryEntity;
import com.botai.agenda.infrastructure.persistence.entity.BusinessCategoryId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface BusinessCategoryJpaRepository extends JpaRepository<BusinessCategoryEntity, BusinessCategoryId> {

    List<BusinessCategoryEntity> findAllByIdBusinessId(UUID businessId);

    List<BusinessCategoryEntity> findAllByIdCategoryId(UUID categoryId);

    @Modifying
    @Query("DELETE FROM BusinessCategoryEntity bc WHERE bc.id.businessId = :businessId")
    void deleteAllByBusinessId(@Param("businessId") UUID businessId);

    @Query(value = """
            SELECT c.slug FROM agenda_categories c
            INNER JOIN agenda_business_categories bc ON bc.category_id = c.id
            WHERE bc.business_id = :businessId
            """, nativeQuery = true)
    List<String> findSlugsByBusinessId(@Param("businessId") UUID businessId);
}
