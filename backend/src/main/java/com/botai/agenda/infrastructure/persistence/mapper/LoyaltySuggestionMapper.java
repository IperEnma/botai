package com.botai.agenda.infrastructure.persistence.mapper;

import com.botai.agenda.domain.model.LoyaltySuggestion;
import com.botai.agenda.infrastructure.persistence.entity.LoyaltySuggestionEntity;

public final class LoyaltySuggestionMapper {

    private LoyaltySuggestionMapper() {}

    public static LoyaltySuggestionEntity toEntity(LoyaltySuggestion domain) {
        LoyaltySuggestionEntity e = new LoyaltySuggestionEntity();
        e.setId(domain.getId());
        e.setBusinessId(domain.getBusinessId());
        e.setUserId(domain.getUserId());
        e.setTriggerRule(domain.getTriggerRule());
        e.setEstado(domain.getEstado());
        return e;
    }

    public static LoyaltySuggestion toDomain(LoyaltySuggestionEntity e) {
        return new LoyaltySuggestion(
                e.getId(),
                e.getBusinessId(),
                e.getUserId(),
                e.getTriggerRule(),
                e.getEstado(),
                e.getCreatedAt(),
                e.getUpdatedAt()
        );
    }
}
