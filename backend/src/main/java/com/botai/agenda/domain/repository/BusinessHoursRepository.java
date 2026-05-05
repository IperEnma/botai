package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.BusinessHours;

import java.util.List;
import java.util.UUID;

public interface BusinessHoursRepository {

    List<BusinessHours> findByBusinessId(UUID businessId);

    void deleteByBusinessId(UUID businessId);

    List<BusinessHours> saveAll(List<BusinessHours> hours);
}
