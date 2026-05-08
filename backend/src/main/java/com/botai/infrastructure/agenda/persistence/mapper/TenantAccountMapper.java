package com.botai.infrastructure.agenda.persistence.mapper;

import com.botai.domain.agenda.model.TenantAccount;
import com.botai.infrastructure.agenda.persistence.entity.TenantAccountEntity;

/**
 * Conversión entre {@link TenantAccountEntity} y el POJO de dominio {@link TenantAccount}.
 */
public final class TenantAccountMapper {

    private TenantAccountMapper() {
    }

    public static TenantAccount toDomain(TenantAccountEntity entity) {
        if (entity == null) {
            return null;
        }
        return new TenantAccount(
                entity.getTenantId(),
                entity.getNombrePropietario(),
                entity.getEmail(),
                entity.getGoogleLinkedEmail(),
                entity.getNumero(),
                entity.getTelefono(),
                entity.getAccessCode(),
                entity.isActivo(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

    public static TenantAccountEntity toEntity(TenantAccount account) {
        if (account == null) {
            return null;
        }
        TenantAccountEntity entity = new TenantAccountEntity();
        entity.setTenantId(account.getTenantId());
        entity.setNombrePropietario(account.getNombrePropietario());
        entity.setEmail(account.getEmail());
        entity.setGoogleLinkedEmail(account.getGoogleLinkedEmail());
        entity.setNumero(account.getNumero());
        entity.setTelefono(account.getTelefono());
        entity.setAccessCode(account.getAccessCode());
        entity.setActivo(account.isActivo());
        entity.setCreatedAt(account.getCreatedAt());
        entity.setUpdatedAt(account.getUpdatedAt());
        return entity;
    }
}
