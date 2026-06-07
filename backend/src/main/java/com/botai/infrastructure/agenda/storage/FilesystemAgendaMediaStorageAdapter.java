package com.botai.infrastructure.agenda.storage;

import com.botai.domain.agenda.service.AgendaMediaStorageKeys;
import com.botai.domain.agenda.service.AgendaMediaStoragePort;
import com.botai.domain.agenda.service.AgendaStoredMedia;
import com.botai.infrastructure.agenda.config.AgendaUploadProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Optional;

/**
 * Persiste uploads en el directorio local configurado ({@code uploads.dir}).
 */
@Component
@ConditionalOnProperty(name = "agenda.media.storage", havingValue = "filesystem")
public class FilesystemAgendaMediaStorageAdapter implements AgendaMediaStoragePort {

    private final AgendaUploadProperties uploadProperties;

    public FilesystemAgendaMediaStorageAdapter(AgendaUploadProperties uploadProperties) {
        this.uploadProperties = uploadProperties;
    }

    @Override
    public String store(String storageKey, byte[] data, String contentType) {
        String normalized = AgendaMediaStorageKeys.normalize(storageKey);
        try {
            Path target = Paths.get(uploadProperties.getDir(), normalized);
            Path parent = target.getParent();
            if (parent != null) {
                Files.createDirectories(parent);
            }
            Files.write(target, data);
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo escribir el archivo en disco: " + normalized, e);
        }
        return AgendaMediaStorageKeys.publicUrl(normalized);
    }

    @Override
    public Optional<AgendaStoredMedia> find(String storageKey) {
        String normalized = AgendaMediaStorageKeys.normalize(storageKey);
        Path file = Paths.get(uploadProperties.getDir(), normalized).normalize();
        Path uploadsRoot = Paths.get(uploadProperties.getDir()).normalize();
        if (!file.startsWith(uploadsRoot) || !Files.isRegularFile(file)) {
            return Optional.empty();
        }
        try {
            byte[] data = Files.readAllBytes(file);
            String contentType = AgendaMediaStorageKeys.contentTypeFromPath(normalized);
            return Optional.of(new AgendaStoredMedia(contentType, data));
        } catch (IOException e) {
            return Optional.empty();
        }
    }
}
