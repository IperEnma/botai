package com.botai.application.agenda.usecase.publicclient;

import com.botai.application.agenda.dto.PublicClientProfileResponse;
import com.botai.application.agenda.support.AgendaClientResolver;
import com.botai.application.agenda.support.AgendaPublicClientSessionService;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.UserRepository;
import org.springframework.stereotype.Component;

@Component
public class UpdatePublicClientProfileUseCase {

    private final UserRepository userRepository;
    private final AgendaPublicClientSessionService sessionService;

    public UpdatePublicClientProfileUseCase(UserRepository userRepository,
                                            AgendaPublicClientSessionService sessionService) {
        this.userRepository = userRepository;
        this.sessionService = sessionService;
    }

    public PublicClientProfileResponse execute(String sessionToken, String nombre) {
        AgendaPublicClientSessionService.ClientSession session = sessionService.requireSession(sessionToken);
        User user = userRepository.findById(session.userId())
                .orElseThrow(() -> new IllegalArgumentException("Cliente no encontrado"));
        String trimmed = nombre != null ? nombre.trim() : "";
        if (trimmed.isBlank()) {
            throw new IllegalArgumentException("Nombre obligatorio");
        }
        User updated = userRepository.save(new User(
                user.getId(),
                user.getTenantId(),
                trimmed,
                user.getEmail(),
                user.getTelefono(),
                user.getTipoUsuario(),
                user.isActivo(),
                user.getCreatedAt(),
                user.getUpdatedAt()
        ));
        return new PublicClientProfileResponse(
                updated.getId(),
                updated.getNombre(),
                updated.getTelefono(),
                updated.getEmail(),
                false);
    }
}
