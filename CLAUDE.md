# CLAUDE.md — Guía de trabajo para este repositorio

Este archivo es la instrucción maestra para Claude al trabajar sobre `botai`. **Leelo completo antes de cualquier cambio.**

---

## 🚧 Regla #1 (INNEGOCIABLE): solo trabajamos sobre AGENDA

El backend es **un solo módulo Maven** (`chatbot-engine`) con **capas** (`application`, `domain`, `infrastructure`), rama **`chatbot`** / **`agenda`**, y la clase **`@SpringBootApplication`** en **`com.botai`** (raíz del código). Lo compartido va **dentro de la capa que corresponda** (p. ej. `infrastructure.common` para detalles técnicos transversales), no en un raíz `common` paralelo a las capas.

**Claude NO debe:**
- Modificar ningún archivo bajo `backend/src/main/java/com/botai/application/chatbot/**`, `domain/chatbot/**`, `infrastructure/chatbot/**` (salvo autorización explícita del usuario).
- Modificar ningún archivo bajo `backend/src/main/resources/` que sea exclusivo del bot (salvo añadir claves `agenda.*` al `application.yml`, que se marcan como bloque separado).
- Tocar tablas existentes del bot (`bot`, `appointment`, `conversation`, `faq`, `knowledge_chunk`, `lead`, `menu`, `menu_option`, `message`, `business_hours`, `service`, `feature_config`, `menu_trigger`).
- Añadir valores al enum `BotFeatures` ni columnas a `BotEntity`.

**Claude SÍ debe:**
- Crear y modificar código bajo `backend/src/main/java/com/botai/application/agenda/**`, `domain/agenda/**`, `infrastructure/agenda/**`.
- Colocar utilidades **realmente comunes** en la capa adecuada: `application/common`, `domain/common` o `infrastructure/common` (p. ej. `ThreadLocal` de request → `infrastructure/common`).
- Crear tablas nuevas en el schema `public` con **prefijo obligatorio `agenda_`**.
- Añadir dependencias al `pom.xml` solo si son estrictamente necesarias para AGENDA.
- Añadir bloques de configuración bajo la key `agenda:` en `application.yml`.

Si una tarea parece requerir tocar el bot, **Claude debe detenerse y preguntar al usuario** antes de proceder.

---

## 📋 Contexto del proyecto

- **Stack:** Java 17 + Spring Boot 3.2.5 + PostgreSQL + JPA (Hibernate) + Spring AI (Ollama) + Flutter (frontend).
- **Arquitectura:** hexagonal / ports & adapters. El bot ya sigue este patrón; AGENDA lo replica.
- **Multi-tenant:** todas las entidades llevan `tenant_id` salvo `agenda_categories` (catálogo global).
- **Plan maestro:** ver [PLAN_AGENDA.md](./PLAN_AGENDA.md) para el modelo de datos completo, sprints, endpoints y mejoras. Ese documento manda — si hay conflicto entre algo que Claude quiera hacer y el plan, gana el plan.

---

## 🏗️ Arquitectura del módulo AGENDA

### Estructura de paquetes (por capa, chatbot vs agenda)

```
com.botai
└── ChatbotEngineApplication.java      # @SpringBootApplication (escanea com.botai.**)

com.botai.application
├── chatbot/                           # casos de uso / servicios del bot
└── agenda/
    ├── config/AgendaConfiguration.java  # @Configuration + @EnableScheduling (beans dominio)
    ├── dto/, mapper/, usecase/, …

com.botai.domain
├── chatbot/
└── agenda/                            # model, repository (puertos), service, event, feature, exception

com.botai.infrastructure
├── chatbot/
├── agenda/                            # api, persistence, event, notification, config, …
├── common/                            # transversal técnico (p.ej. ThreadTenantContext)
└── security/                          # transversal (p.ej. JWT /api/**)
```

### Convenciones de nombres

| Capa | Convención | Ejemplo |
|---|---|---|
| Dominio (POJO) | Sustantivo del dominio, inmutable | `Booking` |
| Puerto | `<Nombre>Repository` o `<Nombre>Service` | `BookingRepository` |
| Adapter JPA | `Jpa<Nombre>Repository` | `JpaBookingRepository` |
| Spring Data | `<Nombre>JpaRepository` | `BookingJpaRepository extends JpaRepository<BookingEntity, UUID>` |
| Entity JPA | `<Nombre>Entity` + `@Table(name = "agenda_<nombre_plural>")` | `BookingEntity` → `agenda_bookings` |
| Caso de uso | Verbo+Nombre + `UseCase` | `CreateBookingUseCase` |
| Controller | `<Recurso>Controller` | `BookingController` |
| DTO | `<Verbo><Recurso>Request` / `<Verbo><Recurso>Response` | `CreateBookingRequest` |

---

## 🗄️ Base de datos

- **Schema:** `public` (el mismo del bot).
- **Prefijo obligatorio:** todas las tablas de AGENDA llevan `agenda_` (ej. `agenda_businesses`, `agenda_bookings`). Declarado con `@Table(name = "agenda_...")` en cada `@Entity`.
- **Migraciones:** Flyway bajo `backend/src/main/resources/db/migration/agenda/`. Nombres: `V1__agenda_core_tables.sql`, `V2__agenda_seed_categories.sql`, etc. (ver skill `new-agenda-migration`).
- **Hibernate:** `ddl-auto: validate` para entidades de AGENDA (el bot sigue con `update`). Las entidades nuevas **nunca** deben ser creadas por Hibernate; siempre por Flyway.
- **Auditoría:** todas las entidades de AGENDA incluyen `created_at`, `updated_at` (`@CreatedDate`, `@LastModifiedDate`). Clase base abstracta `BaseAuditableEntity` en `infrastructure/persistence/entity/`.
- **Soft delete:** `businesses`, `services`, `plans` usan `deleted_at` en vez de borrado físico.

---

## 🚩 Feature flags (aislado del bot)

AGENDA tiene su propio sistema. **Jamás** añadir valores a `com.botai.domain.chatbot.feature.BotFeatures`.

- Enum: `com.botai.domain.agenda.feature.AgendaFeatures`
- Puerto: `AgendaFeatureFlagService.isEnabled(feature, tenantId)`
- Tabla: `agenda_tenant_config`
- Guard: interceptor `AgendaFeatureGuard` aplicado a `/api/agenda/tenants/**` y `/api/agenda/me/**`. Si `AGENDA_ENABLED` está off para el tenant → **404 uniforme**.
- Endpoint admin: `GET/PUT /api/agenda/tenants/{tenantId}/features`.

---

## 🌐 Endpoints REST

Patrón:

| Scope | Prefijo |
|---|---|
| Público (sin login) | `/api/agenda/public/**` |
| Admin de plataforma | `/api/agenda/platform/**` (rol `PLATFORM_ADMIN`) |
| Admin de tenant | `/api/agenda/tenants/{tenantId}/**` |
| Usuario final | `/api/agenda/me/**` |

Todos documentados con OpenAPI / Swagger (`springdoc-openapi-starter-webmvc-ui`).

---

## 🧪 Testing

- **Unit:** JUnit 5 + Mockito. Todo `domain/service/*` y `application/usecase/*` tiene test unitario sin Spring.
- **Integration:** `@SpringBootTest(webEnvironment = RANDOM_PORT)` + Testcontainers PostgreSQL (`postgres:16`). Flyway corre en el contenedor y se validan las tablas `agenda_*`.
- **Contract:** `MockMvc` para controllers, con aserciones sobre JSON response.
- **Concurrencia:** tests específicos con `ExecutorService` para validar el bloqueo pesimista en `agenda_user_subscriptions`.
- **Cobertura mínima:** 80% en `domain/`, 60% global del módulo AGENDA.

Ubicación: `backend/src/test/java/com/botai/**/agenda/**` (espejo por capas de `main`).

---

## 🛠️ Comandos útiles

```bash
# Arrancar backend
cd backend && mvn spring-boot:run

# Solo compilar AGENDA (verifica que no rompe el bot)
cd backend && mvn compile

# Correr tests de AGENDA
cd backend && mvn test -Dtest='com.botai.application.agenda.**,com.botai.domain.agenda.**,com.botai.infrastructure.agenda.**'

# Correr Flyway manualmente
cd backend && mvn flyway:migrate -Dflyway.configFiles=flyway-agenda.conf

# Levantar DB local
docker-compose up -d postgres
```

---

## 🔄 Flujo de trabajo sugerido

Cuando el usuario pide una feature de AGENDA:

1. **Leer** `PLAN_AGENDA.md` y localizar en qué sprint / sección cae.
2. **Localizar** los archivos afectados con Grep / Glob (nunca importar a ciegas).
3. **Diseñar primero** (usar subagente `agenda-architect` si es una feature no trivial).
4. **Implementar** respetando el patrón de capas. Para scaffolding usar las skills (`new-agenda-feature`, `new-agenda-entity`, `new-agenda-migration`).
5. **Validar boundaries** con la skill `agenda-boundary-check` o el subagente `agenda-boundary-guard` antes de terminar.
6. **Test** siempre (unit + integration). Sin test, la feature no está terminada.
7. **Revisar** con el subagente `agenda-reviewer` antes de entregar.

---

## 📚 Referencias dentro del repo

- [PLAN_AGENDA.md](./PLAN_AGENDA.md) — plan técnico completo del módulo.
- [backend/docs/ESTRATEGIA_IA_Y_AGENDAR.md](./backend/docs/ESTRATEGIA_IA_Y_AGENDAR.md) — estrategia del bot (solo contexto, **no tocar**).
- [backend/docs/ANALISIS_SPRING_AI_TOOLS.md](./backend/docs/ANALISIS_SPRING_AI_TOOLS.md) — análisis Spring AI del bot (contexto).
- [.claude/agents/](./.claude/agents/) — subagentes especializados.
- [.claude/skills/](./.claude/skills/) — skills para tareas recurrentes.

---

## ✅ Checklist antes de cerrar cualquier cambio

- [ ] No se modificó nada en `com.botai.application.chatbot.**`, `domain/chatbot/**`, `infrastructure/chatbot/**`.
- [ ] No se modificó `BotFeatures`, `BotEntity` ni tablas del bot.
- [ ] Todas las tablas nuevas tienen prefijo `agenda_`.
- [ ] Hay migración Flyway `V*__agenda_*.sql` por cada cambio de schema.
- [ ] Entidades de AGENDA usan `@Table(name = "agenda_...")`.
- [ ] Puerto en `domain/repository/` + adapter en `infrastructure/persistence/jpa/`.
- [ ] Caso de uso en `application/usecase/` (no lógica de negocio en controllers).
- [ ] Hay tests unitarios + integración.
- [ ] `AgendaFeatureGuard` protege los endpoints sensibles.
- [ ] OpenAPI describe los nuevos endpoints.
- [ ] `mvn compile` pasa sin warnings nuevos en el bot.
