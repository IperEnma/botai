package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.LoyaltySuggestionEstado;
import com.botai.agenda.infrastructure.persistence.entity.LoyaltySuggestionEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface LoyaltySuggestionJpaRepository
        extends JpaRepository<LoyaltySuggestionEntity, UUID> {

    Optional<LoyaltySuggestionEntity> findByBusinessIdAndUserIdAndEstado(
            UUID businessId, UUID userId, LoyaltySuggestionEstado estado);

    List<LoyaltySuggestionEntity> findAllByBusinessId(UUID businessId);

    List<LoyaltySuggestionEntity> findAllByBusinessIdAndEstado(
            UUID businessId, LoyaltySuggestionEstado estado);
}
