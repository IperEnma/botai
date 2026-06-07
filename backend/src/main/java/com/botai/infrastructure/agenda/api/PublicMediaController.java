package com.botai.infrastructure.agenda.api;

import com.botai.infrastructure.agenda.config.AgendaUploadProperties;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.core.io.FileSystemResource;
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

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.Locale;
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

    private final AgendaUploadProperties uploadProperties;

    public PublicMediaController(AgendaUploadProperties uploadProperties) {
        this.uploadProperties = uploadProperties;
    }

    @GetMapping("/{*relativePath}")
    @Operation(summary = "Imagen pública por path relativo bajo uploads/")
    public ResponseEntity<Resource> getMedia(@PathVariable("relativePath") String relativePath) {
        String normalized = relativePath.replace('\\', '/');
        if (normalized.contains("..") || normalized.startsWith("/")) {
            throw new ResponseStatusException(NOT_FOUND);
        }
        boolean allowed = ALLOWED_PREFIXES.stream().anyMatch(normalized::startsWith);
        if (!allowed) {
            throw new ResponseStatusException(NOT_FOUND);
        }

        Path file = Paths.get(uploadProperties.getDir(), normalized).normalize();
        Path uploadsRoot = Paths.get(uploadProperties.getDir()).normalize();
        if (!file.startsWith(uploadsRoot) || !Files.isRegularFile(file)) {
            throw new ResponseStatusException(NOT_FOUND);
        }

        String fileName = file.getFileName().toString().toLowerCase(Locale.ROOT);
        MediaType mediaType = guessMediaType(fileName);

        Resource resource = new FileSystemResource(file);
        return ResponseEntity.ok()
                .cacheControl(CacheControl.maxAge(Duration.ofDays(7)).cachePublic())
                .header(HttpHeaders.CONTENT_TYPE, mediaType.toString())
                .body(resource);
    }

    private static MediaType guessMediaType(String fileName) {
        if (fileName.endsWith(".png")) {
            return MediaType.IMAGE_PNG;
        }
        if (fileName.endsWith(".webp")) {
            return MediaType.parseMediaType("image/webp");
        }
        if (fileName.endsWith(".gif")) {
            return MediaType.IMAGE_GIF;
        }
        return MediaType.IMAGE_JPEG;
    }
}
