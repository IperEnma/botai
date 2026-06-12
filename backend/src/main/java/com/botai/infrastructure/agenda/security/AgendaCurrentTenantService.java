package com.botai.infrastructure.agenda.security;

import com.botai.application.agenda.security.AgendaUserPrincipal;
import com.botai.domain.agenda.exception.AgendaTenantNotResolvedException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.springframework.stereotype.Service;

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

    private final BusinessRepository businessRepository;
    private final AgendaUserContext userContext;

    public AgendaCurrentTenantService(BusinessRepository businessRepository,
                                      AgendaUserContext userContext) {
        this.businessRepository = businessRepository;
        this.userContext = userContext;
    }

    public String requireTenantId() {
        return findTenantId()
                .orElseThrow(AgendaTenantNotResolvedException::new);
    }

    /**
     * Resuelve el tenant del JWT delegando en {@link AgendaUserContext}, que ya
     * cubre ambos caminos: dueño (TenantAccount.email / google_linked_email) y
     * miembro invitado (users.email → tenant del usuario).
     */
    public Optional<String> findTenantId() {
        AgendaUserPrincipal principal = userContext.principal();
        String tenantId = principal.getTenantId();
        if (tenantId == null || tenantId.isBlank()) {
            return Optional.empty();
        }
        return Optional.of(tenantId);
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
