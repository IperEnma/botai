package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.BusinessTagEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface BusinessTagJpaRepository extends JpaRepository<BusinessTagEntity, UUID> {

    List<BusinessTagEntity> findByBusinessIdOrderByTypeAscValueAsc(UUID businessId);

    List<BusinessTagEntity> findByBusinessIdInOrderByBusinessIdAscTypeAscValueAsc(Collection<UUID> businessIds);

    @Modifying
    @Query("DELETE FROM BusinessTagEntity t WHERE t.businessId = :businessId")
    void deleteByBusinessId(@Param("businessId") UUID businessId);
}
