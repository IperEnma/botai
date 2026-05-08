package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.LoyaltySuggestion;
import com.botai.domain.agenda.model.LoyaltySuggestionEstado;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface LoyaltySuggestionRepository {

    LoyaltySuggestion save(LoyaltySuggestion suggestion);

    Optional<LoyaltySuggestion> findById(UUID id);

    Optional<LoyaltySuggestion> findPendingByBusinessIdAndUserId(UUID businessId, UUID userId);

    List<LoyaltySuggestion> findAllByBusinessId(UUID businessId);

    List<LoyaltySuggestion> findAllByBusinessIdAndEstado(UUID businessId, LoyaltySuggestionEstado estado);
}
