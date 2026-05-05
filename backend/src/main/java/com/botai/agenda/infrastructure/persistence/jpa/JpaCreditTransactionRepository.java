package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.CreditTransaction;
import com.botai.agenda.domain.repository.CreditTransactionRepository;
import com.botai.agenda.infrastructure.persistence.entity.CreditTransactionEntity;
import com.botai.agenda.infrastructure.persistence.mapper.CreditTransactionMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public class JpaCreditTransactionRepository implements CreditTransactionRepository {

    private final CreditTransactionJpaRepository jpa;

    public JpaCreditTransactionRepository(CreditTransactionJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public CreditTransaction save(CreditTransaction tx) {
        CreditTransactionEntity entity = CreditTransactionMapper.toEntity(tx);
        if (entity.getId() == null) {
            entity.setId(UUID.randomUUID());
        }
        CreditTransactionEntity saved = jpa.save(entity);
        return CreditTransactionMapper.toDomain(saved);
    }

    @Override
    public List<CreditTransaction> findAllBySubscriptionIdOrderByCreatedAtDesc(UUID subscriptionId) {
        return jpa.findAllBySubscriptionIdOrderByCreatedAtDesc(subscriptionId).stream()
                .map(CreditTransactionMapper::toDomain)
                .toList();
    }
}
