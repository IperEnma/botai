package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.BusinessSettings;

import java.util.Optional;
import java.util.UUID;

public interface BusinessSettingsRepository {

    BusinessSettings save(BusinessSettings settings);

    Optional<BusinessSettings> findByBusinessId(UUID businessId);
}
