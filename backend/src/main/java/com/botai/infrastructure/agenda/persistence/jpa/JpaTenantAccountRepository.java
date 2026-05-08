package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.TenantAccount;
import com.botai.domain.agenda.repository.TenantAccountRepository;
import com.botai.infrastructure.agenda.persistence.entity.TenantAccountEntity;
import com.botai.infrastructure.agenda.persistence.mapper.TenantAccountMapper;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Adaptador JPA que implementa el puerto {@link TenantAccountRepository}.
 */
@Repository
public class JpaTenantAccountRepository implements TenantAccountRepository {

    private final TenantAccountJpaRepository jpa;

    public JpaTenantAccountRepository(TenantAccountJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Optional<TenantAccount> findByEmail(String email) {
        return jpa.findByEmail(email).map(TenantAccountMapper::toDomain);
    }

    @Override
    public Optional<TenantAccount> findByNumero(String numero) {
        return jpa.findByNumero(numero).map(TenantAccountMapper::toDomain);
    }

    @Override
    public Optional<TenantAccount> findByGoogleLinkedEmail(String googleLinkedEmail) {
        return jpa.findByGoogleLinkedEmail(googleLinkedEmail).map(TenantAccountMapper::toDomain);
    }

    @Override
    public boolean existsByEmail(String email) {
        return jpa.existsByEmail(email);
    }

    @Override
    public boolean existsByNumero(String numero) {
        return jpa.existsByNumero(numero);
    }

    @Override
    public boolean existsByGoogleLinkedEmail(String googleLinkedEmail) {
        return jpa.existsByGoogleLinkedEmail(googleLinkedEmail);
    }

    @Override
    public TenantAccount save(TenantAccount account) {
        TenantAccountEntity entity = TenantAccountMapper.toEntity(account);
        TenantAccountEntity saved = jpa.save(entity);
        return TenantAccountMapper.toDomain(saved);
    }

    @Override
    public Optional<TenantAccount> findByTenantId(String tenantId) {
        return jpa.findById(tenantId).map(TenantAccountMapper::toDomain);
    }

    @Override
    public Optional<TenantAccount> findByAccessCode(String accessCode) {
        return jpa.findByAccessCode(accessCode).map(TenantAccountMapper::toDomain);
    }
}
