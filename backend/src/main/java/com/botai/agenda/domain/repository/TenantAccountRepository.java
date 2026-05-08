package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.TenantAccount;

import java.util.Optional;

/**
 * Puerto de dominio para la persistencia de cuentas de tenant.
 */
public interface TenantAccountRepository {

    Optional<TenantAccount> findByEmail(String email);

    Optional<TenantAccount> findByNumero(String numero);

    Optional<TenantAccount> findByGoogleLinkedEmail(String googleLinkedEmail);

    boolean existsByEmail(String email);

    boolean existsByNumero(String numero);

    boolean existsByGoogleLinkedEmail(String googleLinkedEmail);

    TenantAccount save(TenantAccount account);

    Optional<TenantAccount> findByTenantId(String tenantId);

    Optional<TenantAccount> findByAccessCode(String accessCode);
}
