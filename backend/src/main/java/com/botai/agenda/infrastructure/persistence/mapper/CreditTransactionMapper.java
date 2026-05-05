package com.botai.agenda.infrastructure.persistence.mapper;

import com.botai.agenda.domain.model.CreditTransaction;
import com.botai.agenda.infrastructure.persistence.entity.CreditTransactionEntity;

public final class CreditTransactionMapper {

    private CreditTransactionMapper() {
    }

    public static CreditTransaction toDomain(CreditTransactionEntity entity) {
        if (entity == null) {
            return null;
        }
        return new CreditTransaction(
                entity.getId(),
                entity.getSubscriptionId(),
                entity.getMonto(),
                entity.getMotivo(),
                entity.getBookingId(),
                entity.getCreatedAt()
        );
    }

    public static CreditTransactionEntity toEntity(CreditTransaction tx) {
        if (tx == null) {
            return null;
        }
        CreditTransactionEntity entity = new CreditTransactionEntity();
        entity.setId(tx.getId());
        entity.setSubscriptionId(tx.getSubscriptionId());
        entity.setMonto(tx.getMonto());
        entity.setMotivo(tx.getMotivo());
        entity.setBookingId(tx.getBookingId());
        entity.setCreatedAt(tx.getCreatedAt());
        return entity;
    }
}
