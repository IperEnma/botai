package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.BusinessHours;
import com.botai.domain.agenda.repository.BusinessHoursRepository;
import com.botai.infrastructure.agenda.persistence.mapper.BusinessHoursMapper;
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
        // Evita que el siguiente saveAll inserte antes de que el DELETE llegue a BD (23505 en UK business_id+dia_semana).
        jpa.flush();
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
