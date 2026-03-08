package com.botai.chatbot.infrastructure.persistence.jpa;

import com.botai.chatbot.infrastructure.persistence.entity.BusinessHoursEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface BusinessHoursJpaRepository extends JpaRepository<BusinessHoursEntity, Long> {

    List<BusinessHoursEntity> findByTenantIdOrderByDayOfWeek(String tenantId);

    @Transactional
    @Modifying
    void deleteByTenantId(String tenantId);
}
