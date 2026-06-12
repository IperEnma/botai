package com.botai.infrastructure.agenda.config;

import com.botai.application.agenda.security.AgendaUserPrincipal;
import com.botai.infrastructure.agenda.security.AgendaUserContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;

import java.util.function.Supplier;

/**
 * Wiring de RBAC para Agenda:
 * <ul>
 *   <li>Activa {@code @PreAuthorize} en controladores y use cases.</li>
 *   <li>Expone el principal efectivo como {@link Supplier} para que
 *       {@code AgendaAuthorizationService} (capa de aplicación) no dependa
 *       directamente del request-scope de infraestructura.</li>
 * </ul>
 */
@Configuration
@EnableMethodSecurity(prePostEnabled = true)
public class AgendaRbacConfig {

    @Bean
    public Supplier<AgendaUserPrincipal> agendaUserPrincipalSupplier(AgendaUserContext context) {
        return context::principal;
    }
}
