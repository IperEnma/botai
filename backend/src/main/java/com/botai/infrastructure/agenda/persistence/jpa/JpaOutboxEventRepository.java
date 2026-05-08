package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.OutboxEvent;
import com.botai.domain.agenda.repository.OutboxEventRepository;
import com.botai.infrastructure.agenda.persistence.entity.OutboxEventEntity;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class JpaOutboxEventRepository implements OutboxEventRepository {

    private final OutboxEventJpaRepository jpa;

    public JpaOutboxEventRepository(OutboxEventJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public OutboxEvent save(OutboxEvent event) {
        return jpa.save(OutboxEventEntity.fromDomain(event)).toDomain();
    }

    @Override
    public List<OutboxEvent> findPending() {
        return jpa.findByStatus(OutboxEvent.STATUS_PENDING)
                .stream()
                .map(OutboxEventEntity::toDomain)
                .toList();
    }
}
