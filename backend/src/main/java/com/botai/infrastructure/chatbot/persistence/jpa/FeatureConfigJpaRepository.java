package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.infrastructure.chatbot.persistence.entity.FeatureConfigEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FeatureConfigJpaRepository extends JpaRepository<FeatureConfigEntity, Long> {

    Optional<FeatureConfigEntity> findByTenantIdAndFeatureKey(String tenantId, String featureKey);
}
