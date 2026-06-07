package com.botai.infrastructure.agenda.api;

import com.botai.infrastructure.agenda.support.OpenStreetMapPreviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.time.Duration;

import static org.springframework.http.HttpStatus.NOT_FOUND;

@RestController
@RequestMapping("/api/agenda/public/map-preview")
@Tag(name = "Agenda Public · Map preview", description = "Miniatura OSM para ubicación en perfil público")
public class PublicMapPreviewController {

    private final OpenStreetMapPreviewService mapPreviewService;

    public PublicMapPreviewController(OpenStreetMapPreviewService mapPreviewService) {
        this.mapPreviewService = mapPreviewService;
    }

    @GetMapping
    @Operation(summary = "Imagen PNG estática del mapa (OpenStreetMap) para una dirección")
    public ResponseEntity<byte[]> preview(
            @RequestParam("address") String address,
            @RequestParam(value = "size", defaultValue = "192") int size) {
        byte[] png = mapPreviewService.fetchPreviewPng(address, size)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "No se pudo geocodificar la dirección"));
        return ResponseEntity.ok()
                .contentType(MediaType.IMAGE_PNG)
                .cacheControl(CacheControl.maxAge(Duration.ofDays(7)).cachePublic())
                .body(png);
    }
}
