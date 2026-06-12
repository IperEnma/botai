package com.botai.application.agenda.security;

import com.botai.domain.agenda.model.Role;
import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;
import java.util.function.Supplier;

/**
 * Bridge entre {@code @PreAuthorize} y el dominio. Cada método mapea una
 * capacidad de la matriz de permisos (ver {@code AGENDA_RBAC_ENDPOINTS.md}).
 *
 * <p>Registrado como bean {@code "authz"} para que SpEL pueda invocarlo:
 * {@code @PreAuthorize("@authz.canManageBusiness(#businessId)")}.</p>
 *
 * <p>El {@link AgendaUserPrincipal} se obtiene del {@link Supplier} inyectado
 * — en runtime es {@code AgendaUserContext::principal} (request-scoped, lazy);
 * en tests, una lambda que devuelve un principal preparado. Esta indirección
 * evita acoplar la capa de aplicación al request-scope de infraestructura.</p>
 */
@Component("authz")
public class AgendaAuthorizationService {

    private final Supplier<AgendaUserPrincipal> principalSupplier;
    private final BusinessRepository businessRepository;
    private final StaffMemberRepository staffMemberRepository;

    public AgendaAuthorizationService(Supplier<AgendaUserPrincipal> principalSupplier,
                                       BusinessRepository businessRepository,
                                       StaffMemberRepository staffMemberRepository) {
        this.principalSupplier = principalSupplier;
        this.businessRepository = businessRepository;
        this.staffMemberRepository = staffMemberRepository;
    }

    /**
     * Resuelve el {@code staffMemberId} del usuario actual dentro de la sucursal
     * dada. Devuelve vacío si el JWT no está autenticado o si el usuario no
     * tiene perfil de staff en esa sucursal. Usado para gatear acciones
     * "solo sobre mis propias reservas".
     */
    public Optional<UUID> currentUserStaffMemberId(UUID businessId) {
        AgendaUserPrincipal pr = p();
        UUID userId = pr.getUserId();
        if (userId == null || businessId == null) return Optional.empty();
        return staffMemberRepository.findByUserIdAndBusinessId(userId, businessId)
                .map(StaffMember::getId);
    }

    // ─── Plataforma ──────────────────────────────────────────────────────────

    public boolean isPlatformAdmin() {
        return p().isPlatformAdmin();
    }

    // ─── Tenant ──────────────────────────────────────────────────────────────

    public boolean isOwner() {
        return p().isOwner();
    }

    /** OW + TA. */
    public boolean isTenantAdmin() {
        return p().isAdministrative();
    }

    /** Acciones reservadas a OWNER (eliminar workspace, transferir propiedad, gestionar admins). */
    public boolean canManageTenant() {
        return p().isOwner();
    }

    /**
     * Quién puede invitar a qué rol:
     * <ul>
     *   <li>{@code TENANT_ADMIN}: solo {@code OWNER} (no creamos otros admins).</li>
     *   <li>{@code RECEPTION}, {@code STAFF_VIEWER}, {@code STAFF_OPERATOR}: {@code OWNER} o {@code TENANT_ADMIN}.</li>
     *   <li>Otros valores: rechazados.</li>
     * </ul>
     */
    public boolean canInviteRole(String roleName) {
        if (roleName == null) return false;
        Role role;
        try {
            role = Role.valueOf(roleName);
        } catch (IllegalArgumentException e) {
            return false;
        }
        AgendaUserPrincipal pr = p();
        return switch (role) {
            case TENANT_ADMIN -> pr.isOwner();
            case RECEPTION, STAFF_VIEWER, STAFF_OPERATOR -> pr.isAdministrative();
            // OWNER / PLATFORM_ADMIN / CLIENT no se invitan por este flujo.
            default -> false;
        };
    }

    // ─── Business (sucursal) ────────────────────────────────────────────────

    /** El business pertenece al tenant actual (tenant scope). */
    public boolean tenantOwnsBusiness(UUID businessId) {
        if (businessId == null) return false;
        AgendaUserPrincipal pr = p();
        if (pr.getTenantId() == null) return false;
        return businessRepository.findByIdAndTenantId(businessId, pr.getTenantId()).isPresent();
    }

    /** Ver datos del negocio (config, fotos, staff list, servicios…). */
    public boolean canViewBusiness(UUID businessId) {
        AgendaUserPrincipal pr = p();
        if (pr.isPlatformAdmin()) return true;
        if (!tenantOwnsBusiness(businessId)) return false;
        if (pr.isAdministrative()) return true;
        return pr.hasAnyBusinessRole(businessId,
                Role.RECEPTION, Role.STAFF_VIEWER, Role.STAFF_OPERATOR);
    }

    /**
     * Mutar configuración del negocio: servicios, staff, horarios, branding,
     * plantillas, planes, settings, fotos, fidelización.
     * <p>OW + TA dentro del tenant del business.</p>
     */
    public boolean canManageBusiness(UUID businessId) {
        AgendaUserPrincipal pr = p();
        return pr.isAdministrative() && tenantOwnsBusiness(businessId);
    }

    /** Acciones de negocio reservadas a OWNER (configurar bot, feature flags del tenant). */
    public boolean canManageBusinessOwnerOnly(UUID businessId) {
        AgendaUserPrincipal pr = p();
        return pr.isOwner() && tenantOwnsBusiness(businessId);
    }

    /**
     * Gestionar agenda completa del negocio (reservas de cualquier profesional):
     * OW + TA + RC ⓑ.
     */
    public boolean canManageAgenda(UUID businessId) {
        AgendaUserPrincipal pr = p();
        if (!tenantOwnsBusiness(businessId)) return false;
        if (pr.isAdministrative()) return true;
        return pr.hasBusinessRole(Role.RECEPTION, businessId);
    }

    /**
     * Ver agenda — incluye OW/TA/RC (todo el negocio) y SV/SO (solo la propia,
     * filtro server-side aplicado por el repositorio).
     */
    public boolean canViewAgenda(UUID businessId) {
        AgendaUserPrincipal pr = p();
        if (pr.isPlatformAdmin()) return true;
        if (!tenantOwnsBusiness(businessId)) return false;
        if (pr.isAdministrative()) return true;
        return pr.hasAnyBusinessRole(businessId,
                Role.RECEPTION, Role.STAFF_VIEWER, Role.STAFF_OPERATOR);
    }

    /**
     * Crear/modificar una reserva. {@code targetStaffId} es el profesional al
     * que se le asigna la reserva (puede ser {@code null} si aún no se asignó):
     * <ul>
     *   <li>OW + TA: cualquier staff del negocio.</li>
     *   <li>RC ⓑ: cualquier staff del negocio.</li>
     *   <li>SO ⓑⓞ: solo si {@code targetStaffId} == su propio staffMemberId.</li>
     * </ul>
     */
    public boolean canManageBookingFor(UUID businessId, UUID targetStaffId) {
        AgendaUserPrincipal pr = p();
        if (!tenantOwnsBusiness(businessId)) return false;
        if (pr.isAdministrative()) return true;
        if (pr.hasBusinessRole(Role.RECEPTION, businessId)) return true;
        // STAFF_OPERATOR solo sobre su propio staffMember: resolvemos el
        // staffMemberId del usuario en la sucursal y comparamos contra el
        // target del request. Si no matchea (o el request no trae target),
        // negamos. STAFF sin perfil de staff en esa sucursal cae acá también.
        if (!pr.hasBusinessRole(Role.STAFF_OPERATOR, businessId)) return false;
        if (targetStaffId == null) return false;
        return currentUserStaffMemberId(businessId)
                .map(targetStaffId::equals)
                .orElse(false);
    }

    /**
     * Editar el {@code customSchedule} (horario semanal recurrente) de un
     * staff member. Pasan OW/TA (gestionan todo el equipo) y, además, el
     * propio dueño del staff member (STAFF auto-gestiona su horario).
     */
    public boolean canManageOwnStaffSchedule(UUID businessId, UUID staffId) {
        if (!tenantOwnsBusiness(businessId)) return false;
        if (p().isAdministrative()) return true;
        return currentUserStaffMemberId(businessId)
                .map(staffId::equals)
                .orElse(false);
    }

    /** CRM de clientes: OW + TA + RC ⓑ + SO ⓑ. */
    public boolean canManageClientsCrm(UUID businessId) {
        AgendaUserPrincipal pr = p();
        if (!tenantOwnsBusiness(businessId)) return false;
        if (pr.isAdministrative()) return true;
        return pr.hasAnyBusinessRole(businessId, Role.RECEPTION, Role.STAFF_OPERATOR);
    }

    // ─── Ownership ──────────────────────────────────────────────────────────

    /** El usuario apuntado por el path es el actual (acciones sobre uno mismo). */
    public boolean isCurrentUser(UUID targetUserId) {
        return targetUserId != null && targetUserId.equals(p().getUserId());
    }

    /** El usuario actual tiene cualquier rol activo dentro del tenant resuelto. */
    public boolean isAuthenticatedInTenant() {
        AgendaUserPrincipal pr = p();
        return pr.isAuthenticated() && pr.getTenantId() != null;
    }

    private AgendaUserPrincipal p() {
        AgendaUserPrincipal pr = principalSupplier.get();
        return pr != null ? pr : AgendaUserPrincipal.anonymous();
    }
}
