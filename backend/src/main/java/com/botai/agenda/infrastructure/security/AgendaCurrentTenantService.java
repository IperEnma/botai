package com.botai.agenda.infrastructure.security;

import com.botai.agenda.domain.repository.TenantAccountRepository;
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
        String email = AgendaAuthContext.requireEmail().strip().toLowerCase(Locale.ROOT);
        return tenantAccountRepository.findByEmail(email)
                .or(() -> tenantAccountRepository.findByGoogleLinkedEmail(email))
                .map(a -> a.getTenantId());
    }
}

