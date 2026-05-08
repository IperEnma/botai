package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.LoyaltySuggestionEstado;
import com.botai.infrastructure.agenda.persistence.entity.LoyaltySuggestionEntity;
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
