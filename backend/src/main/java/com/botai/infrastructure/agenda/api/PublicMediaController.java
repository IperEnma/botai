package com.botai.infrastructure.agenda.api;

import com.botai.domain.agenda.service.AgendaMediaStorageKeys;
import com.botai.domain.agenda.service.AgendaMediaStoragePort;
import com.botai.domain.agenda.service.AgendaStoredMedia;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.time.Duration;
import java.util.Set;

import static org.springframework.http.HttpStatus.NOT_FOUND;

/**
 * Sirve imágenes subidas vía la API pública de Agenda (misma base que el resto de endpoints).
 * Útil cuando el proxy no expone {@code /uploads/**} pero sí {@code /api/agenda/**}.
 */
@RestController
@RequestMapping("/api/agenda/public/media")
@Tag(name = "Agenda Public · Media", description = "Imágenes públicas (logo, banner, avatares)")
public class PublicMediaController {

    private static final Set<String> ALLOWED_PREFIXES = Set.of("businesses/", "staff/");

    private final AgendaMediaStoragePort mediaStorage;

    public PublicMediaController(AgendaMediaStoragePort mediaStorage) {
        this.mediaStorage = mediaStorage;
    }

    @GetMapping("/{*relativePath}")
    @Operation(summary = "Imagen pública por path relativo bajo uploads/")
    public ResponseEntity<Resource> getMedia(@PathVariable("relativePath") String relativePath) {
        String normalized = AgendaMediaStorageKeys.normalize(relativePath);
        if (normalized.contains("..")) {
            throw new ResponseStatusException(NOT_FOUND);
        }
        boolean allowed = ALLOWED_PREFIXES.stream().anyMatch(normalized::startsWith);
        if (!allowed) {
            throw new ResponseStatusException(NOT_FOUND);
        }

        AgendaStoredMedia stored = mediaStorage.find(normalized)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND));

        MediaType mediaType = MediaType.parseMediaType(stored.contentType());
        Resource resource = new ByteArrayResource(stored.data());

        return ResponseEntity.ok()
                .cacheControl(CacheControl.maxAge(Duration.ofDays(7)).cachePublic())
                .header(HttpHeaders.CONTENT_TYPE, mediaType.toString())
                .body(resource);
    }
}
