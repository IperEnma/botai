package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.infrastructure.persistence.entity.CreditTransactionEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CreditTransactionJpaRepository extends JpaRepository<CreditTransactionEntity, UUID> {

    List<CreditTransactionEntity> findAllBySubscriptionIdOrderByCreatedAtDesc(UUID subscriptionId);
}
