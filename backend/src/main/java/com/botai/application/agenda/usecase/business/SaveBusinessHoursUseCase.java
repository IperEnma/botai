package com.botai.application.agenda.usecase.business;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.BusinessHours;
import com.botai.domain.agenda.repository.BusinessHoursRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Reemplaza atómicamente los horarios de un negocio. */
@Service
public class SaveBusinessHoursUseCase {

    private final BusinessRepository businessRepository;
    private final BusinessHoursRepository hoursRepository;

    public SaveBusinessHoursUseCase(BusinessRepository businessRepository,
                                    BusinessHoursRepository hoursRepository) {
        this.businessRepository = businessRepository;
        this.hoursRepository = hoursRepository;
    }

    @Transactional
    public List<BusinessHours> execute(String tenantId, UUID businessId,
                                       List<BusinessHours> newHours) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        hoursRepository.deleteByBusinessId(businessId);
        return hoursRepository.saveAll(newHours);
    }
}
