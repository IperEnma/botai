package com.botai.infrastructure.agenda.security;

import com.botai.domain.agenda.exception.AgendaTenantNotResolvedException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.TenantAccountRepository;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

/**
 * Resuelve el tenant del usuario autenticado (JWT → email → cuenta Agenda).
 *
 * <p>Los endpoints {@code /api/agenda/me/**} del panel <strong>nunca</strong> reciben
 * {@code tenantId} en la URL: el scope se deriva aquí y cada recurso (p. ej. {@code businessId})
 * se valida con {@link #requireBusinessOwnedByCurrentTenant(UUID)} para que un usuario
 * no pueda leer ni modificar datos de otro tenant aunque adivine UUIDs.</p>
 */
@Service
public class AgendaCurrentTenantService {

    private final TenantAccountRepository tenantAccountRepository;
    private final BusinessRepository businessRepository;

    public AgendaCurrentTenantService(TenantAccountRepository tenantAccountRepository,
                                      BusinessRepository businessRepository) {
        this.tenantAccountRepository = tenantAccountRepository;
        this.businessRepository = businessRepository;
    }

    public String requireTenantId() {
        return findTenantId()
                .orElseThrow(AgendaTenantNotResolvedException::new);
    }

    public Optional<String> findTenantId() {
        var jwt = AgendaAuthContext.currentJwt();
        if (jwt == null) {
            return Optional.empty();
        }
        String raw = jwt.getClaimAsString("email");
        if (raw == null || raw.isBlank()) {
            return Optional.empty();
        }
        String email = raw.strip().toLowerCase(Locale.ROOT);
        return tenantAccountRepository.findByEmail(email)
                .or(() -> tenantAccountRepository.findByGoogleLinkedEmail(email))
                .map(a -> a.getTenantId());
    }

    /**
     * Asegura que el negocio existe y pertenece al tenant del JWT.
     * Si no, {@link BusinessNotFoundException} (404) sin filtrar existencia en otros tenants.
     */
    public Business requireBusinessOwnedByCurrentTenant(UUID businessId) {
        String tenantId = requireTenantId();
        return businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
    }
}
