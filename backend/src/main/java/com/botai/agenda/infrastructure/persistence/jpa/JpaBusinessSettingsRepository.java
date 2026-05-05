package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.BusinessSettings;
import com.botai.agenda.domain.repository.BusinessSettingsRepository;
import com.botai.agenda.infrastructure.persistence.entity.BusinessSettingsEntity;
import com.botai.agenda.infrastructure.persistence.mapper.BusinessSettingsMapper;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaBusinessSettingsRepository implements BusinessSettingsRepository {

    private final BusinessSettingsJpaRepository jpa;

    public JpaBusinessSettingsRepository(BusinessSettingsJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public BusinessSettings save(BusinessSettings settings) {
        BusinessSettingsEntity entity = BusinessSettingsMapper.toEntity(settings);
        BusinessSettingsEntity saved = jpa.save(entity);
        return BusinessSettingsMapper.toDomain(saved);
    }

    @Override
    public Optional<BusinessSettings> findByBusinessId(UUID businessId) {
        return jpa.findById(businessId).map(BusinessSettingsMapper::toDomain);
    }
}
