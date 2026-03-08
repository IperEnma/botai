package com.botai.chatbot.infrastructure.persistence.jpa;

import com.botai.chatbot.infrastructure.persistence.entity.ServiceEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ServiceJpaRepository extends JpaRepository<ServiceEntity, Long> {

    List<ServiceEntity> findByTenantIdAndActiveTrueOrderBySortOrderAsc(String tenantId);

    /** All services for admin (including inactive). */
    List<ServiceEntity> findByTenantIdOrderBySortOrderAsc(String tenantId);
}
