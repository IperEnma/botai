package com.botai.agenda.application.usecase.search;

import com.botai.agenda.domain.model.BusinessSummary;
import com.botai.agenda.domain.repository.BusinessSearchRepository;
import com.botai.agenda.infrastructure.config.AgendaCacheConfig;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Caso de uso del buscador público. Delega en {@link BusinessSearchRepository}. */
@Service
public class SearchBusinessesUseCase {

    private final BusinessSearchRepository searchRepository;
    private final MeterRegistry meterRegistry;

    public SearchBusinessesUseCase(BusinessSearchRepository searchRepository,
                                   MeterRegistry meterRegistry) {
        this.searchRepository = searchRepository;
        this.meterRegistry = meterRegistry;
    }

    @Cacheable(cacheManager = "agendaCacheManager",
               value = AgendaCacheConfig.CACHE_SEARCH,
               key = "{#term?.toLowerCase(), #tenantId, #limit, #offset}")
    @Transactional(readOnly = true)
    public List<BusinessSummary> execute(String term, String tenantId, int limit, int offset) {
        meterRegistry.counter("agenda.search.queries").increment();
        int safeLimit = Math.max(1, Math.min(limit, 100));
        int safeOffset = Math.max(0, offset);
        return searchRepository.searchByTerm(term, tenantId, safeLimit, safeOffset);
    }
}
