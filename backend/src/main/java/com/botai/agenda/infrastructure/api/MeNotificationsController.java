package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.NotificationResponse;
import com.botai.agenda.domain.model.NotificationEstado;
import com.botai.agenda.domain.repository.NotificationRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/me/notifications")
@Tag(name = "Agenda Me · Notifications", description = "Notificaciones recibidas por el usuario autenticado")
public class MeNotificationsController {

    private static final String USER_ID_HEADER = "X-User-Id";

    private final NotificationRepository notificationRepository;

    public MeNotificationsController(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @GetMapping
    @Operation(summary = "Listar mis notificaciones (filtro opcional por estado)")
    public ResponseEntity<List<NotificationResponse>> list(
            @RequestHeader(USER_ID_HEADER) UUID userId,
            @RequestParam(value = "estado", required = false) NotificationEstado estado) {
        var notifications = estado != null
                ? notificationRepository.findAllByUserIdAndEstado(userId, estado)
                : notificationRepository.findAllByUserId(userId);
        List<NotificationResponse> result = notifications.stream()
                .map(n -> new NotificationResponse(
                        n.getId(), n.getBusinessId(), n.getCanal(),
                        n.getTitulo(), n.getCuerpo(), n.getEstado(), n.getCreatedAt()))
                .toList();
        return ResponseEntity.ok(result);
    }
}
