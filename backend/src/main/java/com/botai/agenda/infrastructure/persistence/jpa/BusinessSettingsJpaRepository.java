package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.infrastructure.persistence.entity.BusinessSettingsEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface BusinessSettingsJpaRepository extends JpaRepository<BusinessSettingsEntity, UUID> {
}
