package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.NotificationCanal;
import com.botai.domain.agenda.model.NotificationTemplate;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface NotificationTemplateRepository {

    NotificationTemplate save(NotificationTemplate template);

    Optional<NotificationTemplate> findById(UUID id);

    Optional<NotificationTemplate> findByBusinessIdAndCodigoAndCanal(
            UUID businessId, String codigo, NotificationCanal canal);

    List<NotificationTemplate> findAllByBusinessId(UUID businessId);

    void deleteById(UUID id);
}
