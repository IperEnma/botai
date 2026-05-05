package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.BusinessSettings;

import java.util.Optional;
import java.util.UUID;

public interface BusinessSettingsRepository {

    BusinessSettings save(BusinessSettings settings);

    Optional<BusinessSettings> findByBusinessId(UUID businessId);
}
