package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.TenantConfigEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TenantConfigJpaRepository extends JpaRepository<TenantConfigEntity, String> {
}
