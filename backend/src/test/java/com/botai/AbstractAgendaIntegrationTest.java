package com.botai;

import com.botai.ChatbotEngineApplication;
import com.botai.application.agenda.security.AgendaAuthorizationService;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * Base de los tests de integración del módulo AGENDA.
 *
 * <p>Usa el patrón Singleton Container: el contenedor PostgreSQL se inicia
 * UNA VEZ por JVM (en el bloque static) y nunca se detiene entre clases.
 * Esto garantiza que {@code @DynamicPropertySource} siempre registre la misma
 * URL y que el Spring context cache funcione correctamente sin timeouts de
 * HikariCP al rotar puertos.</p>
 *
 * <p><b>Opt-in para ejecutarse:</b> requiere variable de entorno
 * {@code AGENDA_IT=true} y Docker disponible en el PATH.</p>
 */
@SpringBootTest(
        classes = ChatbotEngineApplication.class,
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@ActiveProfiles("test")
@EnabledIfEnvironmentVariable(
        named = "AGENDA_IT",
        matches = "true",
        disabledReason = "Tests de integración AGENDA — requieren Docker. Exportá AGENDA_IT=true para habilitarlos."
)
public abstract class AbstractAgendaIntegrationTest {

    @MockBean
    protected AgendaCurrentTenantService agendaCurrentTenantService;

    @MockBean
    protected AgendaAuthorizationService authz;

    @Autowired
    protected BusinessRepository businessRepository;

    @MockBean
    @SuppressWarnings("unused")
    private ChatModel chatModel;

    /** Resuelve el tenant y todos los checks de autorización para tests de integración. */
    protected void stubAgendaTenant(String tenantId) {
        when(agendaCurrentTenantService.requireTenantId()).thenReturn(tenantId);
        when(agendaCurrentTenantService.findTenantId()).thenReturn(Optional.of(tenantId));
        when(agendaCurrentTenantService.requireBusinessOwnedByCurrentTenant(any(UUID.class)))
                .thenAnswer(invocation -> {
                    UUID businessId = invocation.getArgument(0);
                    return businessRepository.findByIdAndTenantId(businessId, tenantId)
                            .orElseThrow(() -> new BusinessNotFoundException(businessId));
                });
        stubAllAuthChecks();
    }

    /** Stubea todos los checks de {@code @PreAuthorize} con valores permisivos. */
    protected void stubAllAuthChecks() {
        when(authz.isTenantAdmin()).thenReturn(true);
        when(authz.isOwner()).thenReturn(true);
        when(authz.isPlatformAdmin()).thenReturn(false);
        when(authz.isAuthenticatedInTenant()).thenReturn(true);
        when(authz.canManageTenant()).thenReturn(true);
        when(authz.canManageBusiness(any())).thenReturn(true);
        when(authz.canViewBusiness(any())).thenReturn(true);
        when(authz.canManageAgenda(any())).thenReturn(true);
        when(authz.canViewAgenda(any())).thenReturn(true);
        when(authz.canManageClientsCrm(any())).thenReturn(true);
        when(authz.canManageBookingFor(any(), any())).thenReturn(true);
        when(authz.isCurrentUser(any())).thenReturn(true);
        when(authz.canInviteRole(any())).thenReturn(true);
        when(authz.tenantOwnsBusiness(any())).thenReturn(true);
    }

    @SuppressWarnings("resource")
    protected static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>(DockerImageName.parse("pgvector/pgvector:pg16"))
                    .withDatabaseName("agenda_test")
                    .withUsername("test")
                    .withPassword("test");

    static {
        POSTGRES.start();
    }

    @DynamicPropertySource
    static void registerDatasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
    }
}
