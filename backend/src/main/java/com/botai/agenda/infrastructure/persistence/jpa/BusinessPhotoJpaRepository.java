package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.infrastructure.persistence.entity.BusinessPhotoEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BusinessPhotoJpaRepository extends JpaRepository<BusinessPhotoEntity, UUID> {

    List<BusinessPhotoEntity> findByBusinessIdOrderByOrdenAsc(UUID businessId);

    int countByBusinessId(UUID businessId);
}
