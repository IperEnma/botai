package com.botai.infrastructure.agenda.security;

import com.botai.domain.agenda.repository.TenantAccountRepository;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.Optional;

/**
 * Resuelve tenantId desde el contexto de seguridad (JWT email).
 */
@Service
public class AgendaCurrentTenantService {

    private final TenantAccountRepository tenantAccountRepository;

    public AgendaCurrentTenantService(TenantAccountRepository tenantAccountRepository) {
        this.tenantAccountRepository = tenantAccountRepository;
    }

    public String requireTenantId() {
        return findTenantId()
                .orElseThrow(() -> new IllegalStateException("No hay tenant Agenda para este usuario."));
    }

    public Optional<String> findTenantId() {
        var jwt = AgendaAuthContext.currentJwt();
        if (jwt == null) return Optional.empty();
        String raw = jwt.getClaimAsString("email");
        if (raw == null || raw.isBlank()) return Optional.empty();
        String email = raw.strip().toLowerCase(Locale.ROOT);
        return tenantAccountRepository.findByEmail(email)
                .or(() -> tenantAccountRepository.findByGoogleLinkedEmail(email))
                .map(a -> a.getTenantId());
    }
}

