package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.TenantAccountEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * Spring Data repository para {@link TenantAccountEntity}.
 */
public interface TenantAccountJpaRepository extends JpaRepository<TenantAccountEntity, String> {

    Optional<TenantAccountEntity> findByEmail(String email);

    Optional<TenantAccountEntity> findByNumero(String numero);

    Optional<TenantAccountEntity> findByGoogleLinkedEmail(String googleLinkedEmail);

    boolean existsByEmail(String email);

    boolean existsByNumero(String numero);

    boolean existsByGoogleLinkedEmail(String googleLinkedEmail);

    Optional<TenantAccountEntity> findByAccessCode(String accessCode);
}
