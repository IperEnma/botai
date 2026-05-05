package com.botai.agenda.application.usecase.search;

import com.botai.agenda.domain.model.BusinessSummary;
import com.botai.agenda.domain.repository.BusinessSearchRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Listado público de negocios por slug de categoría. */
@Service
public class ListBusinessesByCategoryUseCase {

    private final BusinessSearchRepository searchRepository;

    public ListBusinessesByCategoryUseCase(BusinessSearchRepository searchRepository) {
        this.searchRepository = searchRepository;
    }

    @Transactional(readOnly = true)
    public List<BusinessSummary> execute(String slug, int limit, int offset) {
        int safeLimit = Math.max(1, Math.min(limit, 100));
        int safeOffset = Math.max(0, offset);
        return searchRepository.findByCategorySlug(slug, safeLimit, safeOffset);
    }
}
