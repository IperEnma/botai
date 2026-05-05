package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.infrastructure.persistence.entity.TenantConfigEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TenantConfigJpaRepository extends JpaRepository<TenantConfigEntity, String> {
}
