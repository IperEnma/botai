package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.LoyaltySuggestion;
import com.botai.agenda.domain.model.LoyaltySuggestionEstado;
import com.botai.agenda.domain.repository.LoyaltySuggestionRepository;
import com.botai.agenda.infrastructure.persistence.mapper.LoyaltySuggestionMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaLoyaltySuggestionRepository implements LoyaltySuggestionRepository {

    private final LoyaltySuggestionJpaRepository jpa;

    public JpaLoyaltySuggestionRepository(LoyaltySuggestionJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public LoyaltySuggestion save(LoyaltySuggestion suggestion) {
        var entity = LoyaltySuggestionMapper.toEntity(suggestion);
        if (entity.getId() == null) {
            entity.setId(UUID.randomUUID());
        }
        return LoyaltySuggestionMapper.toDomain(jpa.save(entity));
    }

    @Override
    public Optional<LoyaltySuggestion> findById(UUID id) {
        return jpa.findById(id).map(LoyaltySuggestionMapper::toDomain);
    }

    @Override
    public Optional<LoyaltySuggestion> findPendingByBusinessIdAndUserId(UUID businessId, UUID userId) {
        return jpa.findByBusinessIdAndUserIdAndEstado(businessId, userId, LoyaltySuggestionEstado.PENDING)
                .map(LoyaltySuggestionMapper::toDomain);
    }

    @Override
    public List<LoyaltySuggestion> findAllByBusinessId(UUID businessId) {
        return jpa.findAllByBusinessId(businessId).stream()
                .map(LoyaltySuggestionMapper::toDomain)
                .toList();
    }

    @Override
    public List<LoyaltySuggestion> findAllByBusinessIdAndEstado(UUID businessId, LoyaltySuggestionEstado estado) {
        return jpa.findAllByBusinessIdAndEstado(businessId, estado).stream()
                .map(LoyaltySuggestionMapper::toDomain)
                .toList();
    }
}
