package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.BusinessSettingsEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface BusinessSettingsJpaRepository extends JpaRepository<BusinessSettingsEntity, UUID> {
}
