package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.TenantAccount;

import java.util.Optional;

/**
 * Puerto de dominio para la persistencia de cuentas de tenant.
 */
public interface TenantAccountRepository {

    Optional<TenantAccount> findByEmail(String email);

    boolean existsByEmail(String email);

    TenantAccount save(TenantAccount account);

    Optional<TenantAccount> findByTenantId(String tenantId);

    Optional<TenantAccount> findByAccessCode(String accessCode);
}
