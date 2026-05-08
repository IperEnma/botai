package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.CreditTransactionEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CreditTransactionJpaRepository extends JpaRepository<CreditTransactionEntity, UUID> {

    List<CreditTransactionEntity> findAllBySubscriptionIdOrderByCreatedAtDesc(UUID subscriptionId);
}
