package com.botai.infrastructure.agenda.persistence;

import com.botai.domain.agenda.service.AgendaMediaStorageKeys;
import com.botai.domain.agenda.service.AgendaMediaStoragePort;
import com.botai.domain.agenda.service.AgendaStoredMedia;
import com.botai.infrastructure.agenda.persistence.entity.UploadedFileEntity;
import com.botai.infrastructure.agenda.persistence.jpa.UploadedFileJpaRepository;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * Persiste uploads en Postgres ({@code agenda_uploaded_files}).
 */
@Component
@ConditionalOnProperty(name = "agenda.media.storage", havingValue = "database", matchIfMissing = true)
public class JpaAgendaMediaStorageAdapter implements AgendaMediaStoragePort {

    private final UploadedFileJpaRepository repository;

    public JpaAgendaMediaStorageAdapter(UploadedFileJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public String store(String storageKey, byte[] data, String contentType) {
        String normalized = AgendaMediaStorageKeys.normalize(storageKey);

        UploadedFileEntity entity = repository.findById(normalized).orElseGet(UploadedFileEntity::new);
        entity.setStorageKey(normalized);
        entity.setContentType(contentType);
        entity.setData(data);
        if (entity.getCreatedAt() == null) {
            entity.setCreatedAt(LocalDateTime.now());
        }
        repository.save(entity);

        return AgendaMediaStorageKeys.publicUrl(normalized);
    }

    @Override
    public Optional<AgendaStoredMedia> find(String storageKey) {
        String normalized = AgendaMediaStorageKeys.normalize(storageKey);
        return repository.findById(normalized)
                .map(e -> new AgendaStoredMedia(e.getContentType(), e.getData()));
    }
}
