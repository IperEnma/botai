package com.botai.agenda.application.usecase.search;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.model.BusinessSummary;
import com.botai.agenda.domain.repository.BusinessSearchRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Ficha pública de un negocio (solo campos visibles en el directorio). */
@Service
public class GetBusinessPublicUseCase {

    private final BusinessSearchRepository searchRepository;

    public GetBusinessPublicUseCase(BusinessSearchRepository searchRepository) {
        this.searchRepository = searchRepository;
    }

    @Transactional(readOnly = true)
    public BusinessSummary execute(UUID businessId) {
        BusinessSummary summary = searchRepository.findPublicById(businessId);
        if (summary == null) {
            throw new BusinessNotFoundException(businessId);
        }
        return summary;
    }
}
