package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.infrastructure.chatbot.persistence.entity.BusinessHoursEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface BusinessHoursJpaRepository extends JpaRepository<BusinessHoursEntity, Long> {

    @Query("SELECT DISTINCT h.tenantId FROM BusinessHoursEntity h")
    List<String> findDistinctTenantIds();

    List<BusinessHoursEntity> findByTenantIdOrderByDayOfWeek(String tenantId);

    @Transactional
    @Modifying
    void deleteByTenantId(String tenantId);
}
