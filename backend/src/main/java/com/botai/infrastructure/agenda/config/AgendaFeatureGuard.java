package com.botai.infrastructure.agenda.config;

import com.botai.infrastructure.security.context.ThreadTenantContext;
import com.botai.domain.agenda.feature.AgendaFeatureFlagService;
import com.botai.domain.agenda.feature.AgendaFeatures;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Interceptor que protege las rutas sensibles del módulo AGENDA.
 *
 * <p>Evalúa {@code AGENDA_ENABLED} para el tenant de la request:
 * para endpoints autenticados bajo {@code /api/agenda/me/**}.
 * Si el flag está off, responde <b>404</b> uniforme para no revelar la existencia
 * del módulo — concordante con la sección 5 del plan.</p>
 *
 * <p>Recursos del panel ({@code /me/businesses/...} salvo reservas/suscripciones de
 * cliente) exigen tenant resuelto desde el JWT; sin cuenta Agenda → 404.</p>
 *
 * <p>El método {@code afterCompletion} limpia el {@link ThreadTenantContext}
 * para evitar leaks en el pool de threads.</p>
 */
@Component
public class AgendaFeatureGuard implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(AgendaFeatureGuard.class);

    private final AgendaFeatureFlagService featureFlagService;
    private final AgendaCurrentTenantService currentTenant;

    public AgendaFeatureGuard(AgendaFeatureFlagService featureFlagService,
                             AgendaCurrentTenantService currentTenant) {
        this.featureFlagService = featureFlagService;
        this.currentTenant = currentTenant;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws Exception {
        String uri = request.getRequestURI();
        if (uri == null) {
            return true;
        }

        // Solo aplica a rutas autenticadas. Las rutas /public/** se permiten en SecurityFilterChain.
        if (!uri.startsWith("/api/agenda/me/")) {
            return true;
        }

        String tenantId = currentTenant.findTenantId().orElse(null);
        if (requiresResolvedTenant(uri) && (tenantId == null || tenantId.isBlank())) {
            log.debug("AgendaFeatureGuard: sin tenant para uri={}", uri);
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return false;
        }

        if (tenantId == null || tenantId.isBlank()) {
            // Onboarding: tenant-admin, public-link, etc.
            return true;
        }

        ThreadTenantContext.setTenantId(tenantId);
        if (!featureFlagService.isEnabled(AgendaFeatures.AGENDA_ENABLED, tenantId)) {
            log.debug("AgendaFeatureGuard: AGENDA_ENABLED off para tenant={} uri={}", tenantId, uri);
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return false;
        }
        return true;
    }

    /**
     * Rutas del panel de negocio: exigen cuenta Agenda vinculada al JWT.
     * Excluye flujos de cliente final (reservas/suscripciones por {@code X-User-Id}).
     */
    static boolean requiresResolvedTenant(String uri) {
        if (uri.startsWith("/api/agenda/me/tenant-admin")
                || uri.startsWith("/api/agenda/me/public-link")) {
            return false;
        }
        if (uri.equals("/api/agenda/me/businesses")) {
            return true;
        }
        if (!uri.startsWith("/api/agenda/me/businesses/")) {
            return false;
        }
        if (uri.contains("/agenda/bookings")) {
            return true;
        }
        if (uri.contains("/bookings")) {
            return false;
        }
        if (uri.contains("/subscriptions")) {
            return false;
        }
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        ThreadTenantContext.clear();
    }
}
