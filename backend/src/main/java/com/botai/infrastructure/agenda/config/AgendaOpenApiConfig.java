package com.botai.infrastructure.agenda.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuración OpenAPI para el módulo AGENDA.
 *
 * <p>Define un {@link GroupedOpenApi} con paquete base {@code /api/agenda/**}
 * para que la documentación del bot y de AGENDA queden separadas en Swagger UI.</p>
 */
@Configuration
@OpenAPIDefinition(
        info = @Info(title = "AGENDA API", version = "v1",
                description = "API del módulo AGENDA (búsqueda pública, catálogo, tenants)"),
        tags = {
                @Tag(name = "Agenda Public", description = "Endpoints públicos del directorio"),
                @Tag(name = "Agenda Platform", description = "Catálogo global (admin de plataforma)"),
                @Tag(name = "Agenda Tenant", description = "Administración por tenant"),
                @Tag(name = "Agenda Tenant Features", description = "Feature flags por tenant")
        }
)
public class AgendaOpenApiConfig {

    @Bean
    public GroupedOpenApi agendaApi() {
        return GroupedOpenApi.builder()
                .group("agenda")
                .pathsToMatch("/api/agenda/**")
                .build();
    }
}
