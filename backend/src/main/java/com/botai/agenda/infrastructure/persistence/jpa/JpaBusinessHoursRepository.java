package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.BusinessHours;
import com.botai.agenda.domain.repository.BusinessHoursRepository;
import com.botai.agenda.infrastructure.persistence.mapper.BusinessHoursMapper;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Repository
public class JpaBusinessHoursRepository implements BusinessHoursRepository {

    private final AgendaBusinessHoursJpaRepository jpa;

    public JpaBusinessHoursRepository(AgendaBusinessHoursJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public List<BusinessHours> findByBusinessId(UUID businessId) {
        return jpa.findByBusinessId(businessId).stream()
                .map(BusinessHoursMapper::toDomain)
                .toList();
    }

    @Override
    @Transactional
    public void deleteByBusinessId(UUID businessId) {
        jpa.deleteByBusinessId(businessId);
    }

    @Override
    @Transactional
    public List<BusinessHours> saveAll(List<BusinessHours> hours) {
        var entities = hours.stream().map(BusinessHoursMapper::toEntity).toList();
        return jpa.saveAll(entities).stream()
                .map(BusinessHoursMapper::toDomain)
                .toList();
    }
}
