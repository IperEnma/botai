package com.botai.agenda.infrastructure.config;

import com.botai.agenda.domain.context.AgendaTenantContext;
import com.botai.agenda.domain.feature.AgendaFeatureFlagService;
import com.botai.agenda.domain.feature.AgendaFeatures;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Interceptor que protege las rutas sensibles del módulo AGENDA.
 *
 * <p>Evalúa {@code AGENDA_ENABLED} para el tenant de la request:
 * <ul>
 *   <li>{@code /api/agenda/tenants/{tenantId}/**}: extrae {@code tenantId} del path.</li>
 *   <li>{@code /api/agenda/me/tenants/{tenantId}/**}: extrae {@code tenantId} del path.</li>
 * </ul>
 * Si el flag está off, responde <b>404</b> uniforme para no revelar la existencia
 * del módulo — concordante con la sección 5 del plan.</p>
 *
 * <p>El método {@code afterCompletion} limpia el {@link AgendaTenantContext}
 * para evitar leaks en el pool de threads.</p>
 */
@Component
public class AgendaFeatureGuard implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(AgendaFeatureGuard.class);

    private static final Pattern TENANT_URI_PATTERN =
            Pattern.compile("^/api/agenda/tenants/([^/]+)(/.*)?$");

    private static final Pattern ME_TENANT_URI_PATTERN =
            Pattern.compile("^/api/agenda/me/tenants/([^/]+)(/.*)?$");

    private final AgendaFeatureFlagService featureFlagService;

    public AgendaFeatureGuard(AgendaFeatureFlagService featureFlagService) {
        this.featureFlagService = featureFlagService;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws Exception {
        String uri = request.getRequestURI();
        if (uri == null) {
            return true;
        }

        String tenantId = extractTenantId(uri);

        if (tenantId == null) {
            return true;
        }

        if (!featureFlagService.isEnabled(AgendaFeatures.AGENDA_ENABLED, tenantId)) {
            log.debug("AgendaFeatureGuard: AGENDA_ENABLED off para tenant={} uri={}", tenantId, uri);
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return false;
        }
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        AgendaTenantContext.clear();
    }

    private String extractTenantId(String uri) {
        Matcher tenantMatcher = TENANT_URI_PATTERN.matcher(uri);
        if (tenantMatcher.matches()) {
            return tenantMatcher.group(1);
        }
        Matcher meTenantMatcher = ME_TENANT_URI_PATTERN.matcher(uri);
        if (meTenantMatcher.matches()) {
            return meTenantMatcher.group(1);
        }
        return null;
    }
}
