package com.botai.infrastructure.agenda.security;

import com.botai.application.agenda.security.AgendaPrincipalLoader;
import com.botai.application.agenda.security.AgendaUserPrincipal;
import org.springframework.context.annotation.ScopedProxyMode;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;
import org.springframework.web.context.annotation.RequestScope;

/**
 * Cache por request del {@link AgendaUserPrincipal} efectivo.
 *
 * <p>Se carga lazy en la primera invocación dentro del request; las llamadas
 * posteriores reutilizan la misma instancia. Evita golpear la base múltiples
 * veces cuando varias anotaciones {@code @PreAuthorize} se evalúan en la
 * misma request.</p>
 */
@Component
@RequestScope(proxyMode = ScopedProxyMode.TARGET_CLASS)
public class AgendaUserContext {

    private final AgendaPrincipalLoader loader;
    private AgendaUserPrincipal cached;
    private boolean loaded;

    public AgendaUserContext(AgendaPrincipalLoader loader) {
        this.loader = loader;
    }

    public AgendaUserPrincipal principal() {
        if (!loaded) {
            cached = loadFromSecurityContext();
            loaded = true;
        }
        return cached;
    }

    /**
     * Fuerza re-carga del principal desde la base. Solo debe usarse cuando un
     * endpoint mutó las asignaciones de rol del usuario actual durante la
     * misma request (p. ej. bootstrap automático del OWNER).
     */
    public AgendaUserPrincipal reload() {
        cached = loadFromSecurityContext();
        loaded = true;
        return cached;
    }

    private AgendaUserPrincipal loadFromSecurityContext() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            return AgendaUserPrincipal.anonymous();
        }
        Object p = auth.getPrincipal();
        if (!(p instanceof Jwt jwt)) {
            return AgendaUserPrincipal.anonymous();
        }
        String email = jwt.getClaimAsString("email");
        return loader.loadByJwtEmail(email);
    }
}
