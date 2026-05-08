package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.BusinessHours;

import java.util.List;
import java.util.UUID;

public interface BusinessHoursRepository {

    List<BusinessHours> findByBusinessId(UUID businessId);

    void deleteByBusinessId(UUID businessId);

    List<BusinessHours> saveAll(List<BusinessHours> hours);
}
