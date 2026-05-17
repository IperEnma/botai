package com.botai;

import com.botai.ChatbotEngineApplication;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import com.botai.testsupport.PostgresExtensions;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

/**
 * Base de los tests de integración del módulo AGENDA.
 *
 * <p>Levanta un PostgreSQL 16 en Testcontainers y redirige la datasource de
 * Spring Boot a ese contenedor. Flyway corre las migraciones bajo
 * {@code classpath:db/migration/agenda/} automáticamente al arrancar el contexto
 * gracias a {@code AgendaFlywayConfig}.</p>
 *
 * <p><b>Por qué {@code ddl-auto=update}:</b> el bot también tiene entidades JPA
 * cuyas tablas NO están declaradas como migraciones Flyway. Con {@code validate}
 * el startup fallaría. En cambio, con {@code update}, Flyway crea primero las
 * tablas {@code agenda_*} y Hibernate luego crea las del bot — cada módulo vive
 * en su carril.</p>
 *
 * <p><b>Opt-in para ejecutarse:</b> estos tests solo corren si la variable de
 * entorno {@code AGENDA_IT=true}. Sin eso quedan <em>skipped</em>. Motivo: no
 * todos los entornos tienen Docker instalado (ni CI ni máquinas de dev con PATH
 * raro) y no queremos hacer fallar el build. Para correrlos localmente:
 * <pre>
 *   # Windows PowerShell
 *   $env:AGENDA_IT="true"; mvn test
 *   # bash
 *   AGENDA_IT=true mvn test
 * </pre></p>
 */
@SpringBootTest(
        classes = ChatbotEngineApplication.class,
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
@EnabledIfEnvironmentVariable(
        named = "AGENDA_IT",
        matches = "true",
        disabledReason = "Tests de integración AGENDA — requieren Docker. Exportá AGENDA_IT=true para habilitarlos."
)
public abstract class AbstractAgendaIntegrationTest {

    @Container
    @SuppressWarnings("resource")
    /** Misma imagen que docker-compose (pgvector). Extensiones vía {@link PostgresExtensions}. */
    protected static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>(DockerImageName.parse("pgvector/pgvector:pg16"))
                    .withDatabaseName("agenda_test")
                    .withUsername("test")
                    .withPassword("test")
                    .withReuse(true);

    @DynamicPropertySource
    static void registerDatasource(DynamicPropertyRegistry registry) {
        PostgresExtensions.ensure(POSTGRES);
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
    }
}
