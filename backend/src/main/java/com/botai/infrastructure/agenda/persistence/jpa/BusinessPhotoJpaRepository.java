package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.BusinessPhotoEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BusinessPhotoJpaRepository extends JpaRepository<BusinessPhotoEntity, UUID> {

    List<BusinessPhotoEntity> findByBusinessIdOrderByOrdenAsc(UUID businessId);

    int countByBusinessId(UUID businessId);
}
