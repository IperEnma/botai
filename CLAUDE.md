# CLAUDE.md — Guía de trabajo para este repositorio

Este archivo es la instrucción maestra para Claude al trabajar sobre `botai`. **Leelo completo antes de cualquier cambio.**

---

## 🏗️ Monorepo unificado (Agenda + Chatbot)

El backend es **un solo módulo Maven** (`chatbot-engine`) con **capas** (`application`, `domain`, `infrastructure`) y dos dominios en paquetes paralelos: **`agenda`** y **`chatbot`**. La clase **`@SpringBootApplication`** está en **`com.botai`**. Lo transversal va en la capa y subpaquete que corresponda (p. ej. `infrastructure.security.context`), sin un `common` genérico paralelo a las capas.

**Podés modificar ambos dominios** según la tarea del usuario:

| Dominio | Paquetes | Convenciones clave |
|---------|----------|-------------------|
| **Agenda** | `application.agenda`, `domain.agenda`, `infrastructure.agenda` | Tablas nuevas con prefijo `agenda_`, Flyway en `db/migration/agenda/`, `agenda:` en `application.yml` |
| **Chatbot** | `application.chatbot`, `domain.chatbot`, `infrastructure.chatbot` | Tablas del bot existentes, `BotEntity` / `BotFeatures` solo cuando la feature lo requiera |

**Aislamiento entre dominios (sí aplica):**
- **No** `import` directo entre `com.botai.*.agenda` y `com.botai.*.chatbot`. Integración vía APIs REST, eventos, JDBC en capa de infra compartida o contratos explícitos acordados — no acoplar dominios en código.
- Migraciones **Agenda** no deben alterar tablas del bot; migraciones del bot no deben tocar tablas `agenda_*` sin diseño explícito.

Si la integración Agenda ↔ Bot necesita un canal nuevo (p. ej. acción del bot que llama Agenda), implementalo en el lado correcto y documentá el contrato; no cruces imports de dominio.

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
└── security/                          # JWT /api/**, y context/ (p.ej. ThreadTenantContext por request)
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

### Política greenfield (INNEGOCIABLE)

El desarrollo **asume siempre base de datos desde cero**. No hay migraciones retroactivas ni parches sobre esquemas ya desplegados.

**Claude NO debe:**
- Proponer `ALTER TABLE` (ni en Flyway, ni scripts sueltos, ni “ejecutá esto en Render/prod”).
- Asumir que prod/local tiene columnas, tipos o datos legacy distintos al schema actual del repo.
- Sugerir workarounds del tipo “si no migró, corré este SQL a mano”.
- Añadir migraciones solo para cambiar tipos/tamaños de columnas existentes (ej. `VARCHAR(255)` → `TEXT`).

**Claude SÍ debe:**
- Definir el schema correcto **desde el origen**: `@Entity` / `@Column` (bot, Hibernate `ddl-auto: update`) o migraciones Flyway **CREATE** (Agenda).
- Si el schema en código cambió y una BD vieja no coincide → indicar **recrear la base desde cero** (nueva instancia Postgres, `docker-compose down -v`, etc.), no parchearla.
- Dimensionar columnas en la entidad/migración inicial (ej. `whatsapp_access_token` como `TEXT` en `BotEntity` porque el ciphertext cifrado supera 255 chars).

**Ejemplo aplicado:** access token WhatsApp cifrado (`enc:v1:…`) → `@Column(columnDefinition = "TEXT")` en `BotEntity`; sin `ALTER` en prod.

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
5. **Validar aislamiento de paquetes** con `agenda-boundary-check` si el cambio toca Agenda (imports cruzados, prefijos `agenda_`).
6. **Test** siempre (unit + integration). Sin test, la feature no está terminada.
7. **Revisar** con el subagente `agenda-reviewer` antes de entregar.

---

## 📚 Referencias dentro del repo

- [PLAN_AGENDA.md](./PLAN_AGENDA.md) — plan técnico completo del módulo.
- [backend/docs/ESTRATEGIA_IA_Y_AGENDAR.md](./backend/docs/ESTRATEGIA_IA_Y_AGENDAR.md) — estrategia del bot e integración con Agenda.
- [backend/docs/ANALISIS_SPRING_AI_TOOLS.md](./backend/docs/ANALISIS_SPRING_AI_TOOLS.md) — análisis Spring AI del bot.
- [backend/docs/BOT_AGENDA_INTENTS.md](./backend/docs/BOT_AGENDA_INTENTS.md) — intenciones del bot ligadas a Agenda.
- [.claude/agents/](./.claude/agents/) — subagentes especializados.
- [skills/](./skills/) — skills (fuente de verdad, estilo [Prowler](https://github.com/prowler-cloud/prowler)); ver [AGENTS.md](./AGENTS.md) y `./skills/setup.sh`.
- [agents/](./agents/) — subagentes Cursor (symlink vía setup).

---

## ✅ Checklist antes de cerrar cualquier cambio

**Siempre:**
- [ ] `mvn compile` pasa.
- [ ] Tests del área tocada (Agenda y/o chatbot).
- [ ] Sin `import` cruzado `agenda` ↔ `chatbot` (ver `agenda-boundary-check`).

**Si tocó Agenda:**
- [ ] Tablas nuevas con prefijo `agenda_` y migración `V*__agenda_*.sql` si hubo schema.
- [ ] Entidades Agenda: `@Table(name = "agenda_...")`, hexagonal (puerto + adapter + use case).
- [ ] `AgendaFeatureGuard` en endpoints sensibles; OpenAPI actualizado.

**Si tocó Chatbot:**
- [ ] Cambios acotados al paquete `chatbot` y tablas/recursos del bot.
- [ ] `BotFeatures` / `BotEntity` solo si la feature lo exige; sin romper conversaciones existentes sin migración planificada.
