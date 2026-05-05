package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.NotificationCanal;
import com.botai.agenda.domain.model.NotificationTemplate;
import com.botai.agenda.domain.repository.NotificationTemplateRepository;
import com.botai.agenda.infrastructure.persistence.mapper.NotificationTemplateMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaNotificationTemplateRepository implements NotificationTemplateRepository {

    private final NotificationTemplateJpaRepository jpa;

    public JpaNotificationTemplateRepository(NotificationTemplateJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public NotificationTemplate save(NotificationTemplate template) {
        var entity = NotificationTemplateMapper.toEntity(template);
        if (entity.getId() == null) {
            entity.setId(UUID.randomUUID());
        }
        return NotificationTemplateMapper.toDomain(jpa.save(entity));
    }

    @Override
    public Optional<NotificationTemplate> findById(UUID id) {
        return jpa.findById(id).map(NotificationTemplateMapper::toDomain);
    }

    @Override
    public Optional<NotificationTemplate> findByBusinessIdAndCodigoAndCanal(
            UUID businessId, String codigo, NotificationCanal canal) {
        return jpa.findByBusinessIdAndCodigoAndCanal(businessId, codigo, canal)
                .map(NotificationTemplateMapper::toDomain);
    }

    @Override
    public List<NotificationTemplate> findAllByBusinessId(UUID businessId) {
        return jpa.findAllByBusinessId(businessId).stream()
                .map(NotificationTemplateMapper::toDomain)
                .toList();
    }

    @Override
    public void deleteById(UUID id) {
        jpa.deleteById(id);
    }
}
