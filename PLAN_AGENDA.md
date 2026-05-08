# Plan técnico — Paquete **AGENDA** (Agenda Konecta)

> Plan de implementación del módulo **AGENDA** como paquete separado dentro del mismo artifact `chatbot-engine`, totalmente independiente del bot actual. Persiste en la misma base de datos PostgreSQL y en el **mismo schema** (`public`) que el bot, usando **prefijo `agenda_`** en los nombres de tabla para evitar colisiones. Solo backend (Sprint 1–3). Este documento es solo **propuesta de plan** — aún no implementa nada.

---

## 0. Decisiones de arquitectura acordadas

| Dimensión | Decisión |
|---|---|
| Separación de código | Paquete separado `com.botai.agenda.*` dentro del mismo `pom.xml` (`chatbot-engine`) |
| Acoplamiento con el bot | **Independientes. Cero cambios en `com.botai.chatbot.*`.** No se tocan `BookAppointmentAction`, `ViewAppointmentsAction`, `AgendarTools`, `BotFeatures` ni `BotEntity`. AGENDA tiene su propio sistema de feature flags (ver sección 5). |
| Base de datos | PostgreSQL existente, **mismo schema `public`** que el bot. Tablas de AGENDA llevan prefijo `agenda_` para evitar colisiones (ej. `agenda_businesses`, `agenda_bookings`). |
| Alcance de este plan | Backend AGENDA, Sprint 1–3. Web directorio, app Flutter y push se dejan para un plan posterior. |
| Stack | Java 17, Spring Boot 3.2.5, Spring Data JPA, PostgreSQL, Hibernate, Validation |

---

## 1. Visión arquitectónica

AGENDA se construye siguiendo los mismos principios hexagonales que ya usa `com.botai.chatbot`:

- **domain/** → modelos de negocio (POJOs inmutables) + puertos (interfaces `*Repository`, `*Service`)
- **application/** → casos de uso y orquestación
- **infrastructure/** → adaptadores (JPA, REST, eventos, notificaciones)

Convención de nombres replicada del bot: dominio define `XRepository` (interfaz), infraestructura provee `JpaXRepository` que envuelve un `XJpaRepository extends JpaRepository<XEntity, ID>`; conversión explícita `Entity ↔ Domain`.

### 1.1 Nueva estructura de paquetes

Vista **macro** — simetría entre el bot existente y el nuevo módulo AGENDA, ambos con las mismas tres capas hexagonales:

```
com.botai
├── chatbot                        # INTOCADO — bot actual
│   ├── domain
│   ├── application
│   └── infrastructure
└── agenda                         # NUEVO — paquete AGENDA
    ├── domain
    ├── application
    └── infrastructure
```

Vista **detallada** del paquete `agenda`:

```
com.botai.agenda
├── AgendaModuleConfig.java            # @Configuration, @ComponentScan limitado
├── domain
│   ├── model                          # Business, Service, Plan, UserSubscription,
│   │                                  # CreditTransaction, Booking, BookingStatus,
│   │                                  # SubscriptionType (enum), PlanTier (enum),
│   │                                  # CancellationPolicy, LoyaltyRule
│   ├── repository                     # BusinessRepository, PlanRepository,
│   │                                  # BookingRepository, SubscriptionRepository,
│   │                                  # CreditTransactionRepository, ...
│   ├── service                        # BookingDomainService, CreditDomainService,
│   │                                  # CancellationDomainService, LoyaltyDomainService
│   ├── event                          # BookingConfirmed, BookingCancelled,
│   │                                  # CreditDebited, CreditRefunded,
│   │                                  # LoyaltyTriggered (eventos de dominio)
│   └── exception                      # InsufficientCreditsException,
│                                      # SlotUnavailableException, ...
├── application
│   ├── usecase
│   │   ├── business                   # RegisterBusiness, UpdateBusiness, SearchBusinesses
│   │   ├── plan                       # CreatePlan, UpdatePlan, DeactivatePlan
│   │   ├── subscription               # PurchaseSubscription, RenewSubscription
│   │   ├── booking                    # CreateBooking, ConfirmBooking, CancelBooking
│   │   └── loyalty                    # EvaluateLoyaltyRules, SuggestPlanToCustomer
│   ├── dto                            # Request/Response por caso de uso
│   └── mapper                         # MapStruct o manual: DTO ↔ Domain
└── infrastructure
    ├── api                            # REST controllers (/api/agenda/...)
    ├── persistence
    │   ├── entity                     # BusinessEntity, ServiceCatalogEntity,
    │   │                              # PlanEntity, UserSubscriptionEntity,
    │   │                              # CreditTransactionEntity, BookingEntity
    │   └── jpa                        # Jpa*Repository (adapters) + *JpaRepository (Spring Data)
    ├── event                          # ApplicationEventPublisher + @EventListener handlers
    ├── search                         # SynonymSearchAdapter (port impl)
    ├── notification                   # NotificationPort → stub (web/push en fase futura)
    └── config                         # JpaConfig (prefijo agenda_), Jackson, security
```

### 1.2 Aislamiento entre paquetes

- `AgendaModuleConfig` define `@EntityScan("com.botai.agenda.infrastructure.persistence.entity")` y `@EnableJpaRepositories(basePackages = "com.botai.agenda.infrastructure.persistence.jpa")` acotados al paquete AGENDA. El bot ya tiene sus propios scans implícitos; hay que asegurarse de que **ambos escaneos sean explícitos** para no solapar (se hará ajuste menor en configuración de JPA del bot si fuese necesario, sin cambiar lógica).
- Regla de arquitectura: **ningún archivo de `com.botai.agenda` puede importar clases de `com.botai.chatbot`** y viceversa. Se documenta en `CONTRIBUTING.md` y se valida con ArchUnit (opcional).

---

## 2. Modelo de datos — mismo schema, prefijo `agenda_`

Todas las tablas de AGENDA **conviven en el schema `public`** (el mismo que el bot) y usan el **prefijo `agenda_`** para quedar claramente identificadas y evitar cualquier colisión con tablas del bot (`bot`, `appointment`, `conversation`, etc.). Todas llevan `tenant_id` para multi-tenancy (siguiendo el patrón del bot).

> Convención: el prefijo se declara con `@Table(name = "agenda_...")` en cada entity JPA de `com.botai.agenda.infrastructure.persistence.entity`. En código Java los nombres de clase y paquete **no** llevan prefijo (ya están en `com.botai.agenda`), solo las tablas físicas.

| Tabla | Descripción | Campos clave |
|---|---|---|
| `agenda_users` | Usuarios finales (clientes y admins de negocio) | id, tenant_id, nombre, email, telefono, tipo_usuario (`ADMIN`/`CLIENT`), created_at |
| `agenda_businesses` | Negocios registrados | id, tenant_id, nombre, descripcion, search_tags (jsonb, sinónimos específicos del negocio), owner_user_id, activo |
| `agenda_categories` | **Catálogo global** de categorías (Peluquería, Manicure, Yoga, Spa...). **Sin `tenant_id`** — compartido entre tenants. Aquí viven los sinónimos maestros. | id, nombre, slug (`manicure`), synonyms (jsonb: `["uñas","uñitas","mani"]`), icono, activo |
| `agenda_business_categories` | Tabla pivote N:M entre negocios y categorías | business_id, category_id, PK compuesta |
| `agenda_services` | Servicios por negocio (corte, manicura, clase) | id, business_id, nombre, duracion_min, precio, activo |
| `agenda_plans` | Planes que vende un negocio | id, business_id, nombre_plan, tipo (`ILIMITADO_MENSUAL`/`POR_CREDITOS`/`SOLO_RESERVA`/`MIXTO`), tier (`VIP`/`GOLDEN`/`PLATA`), total_creditos, validez_dias, precio, activo |
| `agenda_user_subscriptions` | "Monedero" — suscripción de un usuario a un negocio | id, user_id, plan_id, business_id, saldo_actual, fecha_inicio, fecha_expiracion, estado (`ACTIVE`/`EXPIRED`/`CANCELLED`) |
| `agenda_credit_transactions` | Auditoría inmutable de movimientos | id, subscription_id, monto (+/-), motivo (`RESERVA`/`CANCELACION_DEVUELTA`/`AJUSTE_ADMIN`/`COMPRA`), booking_id (nullable), created_at |
| `agenda_bookings` | Citas | id, user_id, service_id, business_id, subscription_id (nullable → modo `SOLO_RESERVA`), fecha, hora_inicio, hora_fin, estado (`SCHEDULED`/`CONFIRMED`/`CANCELLED`/`COMPLETED`/`NO_SHOW`), tipo_reserva (`SUBSCRIPTION`/`OPEN`), created_at |
| `agenda_business_settings` | Config por negocio | business_id (PK), hours_cancellation_limit, loyalty_min_attendances, loyalty_window_days, expiration_alert_days, expiration_alert_credits, auto_notify_enabled |
| `agenda_loyalty_suggestions` | Sugerencias generadas por el motor | id, business_id, user_id, trigger_rule, created_at, status (`PENDING`/`SENT`/`DISMISSED`) |
| `agenda_notification_templates` | Plantillas editables por el dueño | id, business_id, codigo, canal (`IN_APP`/`EMAIL`/`PUSH`), asunto, cuerpo |
| `agenda_tenant_config` | Feature flags y configuración de AGENDA por tenant (aislada del bot) | tenant_id (PK), agenda_enabled, public_search_enabled, loyalty_engine_enabled, auto_notifications, updated_at |

> Nota sobre `agenda_users`: el bot ya usa `LeadEntity` para sus contactos. **No se fusionan**: son modelos independientes por decisión de desacople total (un `Lead` del bot no es necesariamente un usuario de AGENDA). Si en el futuro conviene unificar, se hará con una migración explícita.

### 2.1 Índices importantes

- `agenda_bookings (business_id, fecha, hora_inicio)` — consulta de calendario
- `agenda_bookings (user_id, estado)` — "mis citas"
- `agenda_user_subscriptions (user_id, business_id, estado)` — saldo vigente
- `agenda_businesses (tenant_id, activo)` — listados por tenant
- `agenda_businesses` + GIN sobre `search_tags` (jsonb) — sinónimos específicos del negocio
- `agenda_categories` + GIN sobre `synonyms` (jsonb) — mapeo maestro "uñas → manicure"
- `agenda_categories (slug)` UNIQUE — identificador estable para URLs y frontend
- `agenda_business_categories (category_id)` — pivote para resolver búsquedas por categoría
- `agenda_credit_transactions (subscription_id, created_at)` — auditoría

### 2.2 Integridad transaccional

La operación "confirmar reserva" (descontar crédito + crear booking + registrar transacción) debe ser **atómica** dentro de una transacción con `@Transactional(isolation = READ_COMMITTED)` y bloqueo pesimista sobre la fila de `agenda_user_subscriptions` para evitar doble descuento en concurrencia:

```sql
SELECT ... FROM agenda_user_subscriptions WHERE id=? FOR UPDATE
```

---

## 3. Lógica de negocio (domain services)

### 3.1 `BookingDomainService`
- `confirmar(Booking, UserSubscription?)`: valida disponibilidad + descuenta crédito (si aplica) + cambia estado.
- `cancelar(Booking, Instant now)`: calcula si está dentro del plazo permitido. Si **sí** → emite `CreditRefunded`. Si **no** → penalización (no devuelve).
- `validarDisponibilidad(business, service, fecha, hora)`: se apoya en `business_settings` y no permite reservas sin slots disponibles (**RF06**).

### 3.2 `CreditDomainService`
- `descontar(subscription)`: valida saldo y vencimiento; escribe `CreditTransaction(-1)`. Si tipo `ILIMITADO_MENSUAL` → no-op (pero sí crea `CreditTransaction` de tipo `RESERVA` con monto 0 para trazabilidad).
- `devolver(subscription, bookingId)`: `CreditTransaction(+1)`.
- `validarVencimiento(subscription, Instant now)`.

### 3.3 `CancellationDomainService`
- Regla: `ahora + hours_cancellation_limit <= booking.fechaHora` → cancelación gratuita.
- La ventana se lee de `business_settings` (configurable por admin del negocio).

### 3.4 `LoyaltyDomainService`
- Escucha `BookingConfirmed`.
- Ejecuta regla: *"usuario sin suscripción con > N asistencias en M días → generar `LoyaltySuggestion`"* donde N y M son configurables por el dueño (`loyalty_min_attendances`, `loyalty_window_days`).
- Si `auto_notify_enabled=true` → dispara `NotificationPort.enviar(template)`.

### 3.5 Búsqueda por sinónimos (`SynonymSearchAdapter`)
- **Fuente principal de sinónimos:** `agenda_categories.synonyms` (jsonb). Ej.: `Manicure` → `["uñas","uñitas","mani"]`. Esto centraliza el diccionario y lo mantiene consistente entre tenants.
- **Fuente secundaria:** `agenda_businesses.search_tags` (jsonb), para sinónimos/apodos propios de un negocio (nombre comercial, barrio, keywords locales).
- **Fase 1 — query:**
  1. Match del término contra `agenda_categories.synonyms` (operador `?` o `@>` con índice GIN) → resuelve a una o varias `category_id`.
  2. Join con `agenda_business_categories` → listado de `business_id` candidatos.
  3. Union con match directo sobre `agenda_businesses.search_tags` y `agenda_businesses.nombre` (ILIKE con `unaccent`) para cubrir el caso de buscar por nombre comercial.
  4. Filtrar por `activo=true` y paginar.
- **Fase 2 (mejora sugerida):** cuando haya volumen, migrar a **PostgreSQL Full-Text Search** con diccionario español + `unaccent`, o indexar las categorías con `pgvector` (mismo motor que usa el bot para RAG) para búsqueda semántica.

---

## 4. Endpoints REST — `/api/agenda/**`

Los endpoints de **admin de negocio** son **me-scoped**: el frontend no envía `tenantId` y el backend lo resuelve desde el contexto de seguridad (JWT validado).

### 4.1 Públicos (sin login — RNF01)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/agenda/public/search?q=uñas&tenantId=...` | Buscador por sinónimo (resuelve vía `agenda_categories`) |
| GET | `/api/agenda/public/categories` | Catálogo global de categorías (para UI del buscador, filtros, chips) |
| GET | `/api/agenda/public/categories/{slug}/businesses` | Negocios de una categoría |
| GET | `/api/agenda/public/businesses/{id}` | Ficha pública de negocio (incluye sus categorías) |
| GET | `/api/agenda/public/businesses/{id}/services` | Servicios disponibles |

### 4.1.1 Admin de plataforma (catálogo global de categorías)
Como las categorías son globales, su CRUD vive bajo `/api/agenda/platform/**` y requiere rol `PLATFORM_ADMIN` (no admin de tenant). El admin de negocio solo **asocia/desasocia** categorías a su negocio — no las crea.

| Método | Ruta |
|---|---|
| GET / POST / PUT / DELETE | `/api/agenda/platform/categories` |
| PUT | `/api/agenda/platform/categories/{id}/synonyms` (merge de sinónimos) |

### 4.2 Admin de negocio
| Método | Ruta |
|---|---|
| GET / PUT | `/api/agenda/me/features` (flags propios de AGENDA) |
| POST / GET / PUT | `/api/agenda/me/businesses` |
| PUT | `/api/agenda/me/businesses/{businessId}/categories` (asociar N categorías del catálogo global) |
| CRUD | `/api/agenda/me/businesses/{businessId}/services` |
| CRUD | `/api/agenda/me/businesses/{businessId}/plans` |
| GET / PUT | `/api/agenda/me/businesses/{businessId}/settings` |
| GET | `/api/agenda/me/businesses/{businessId}/loyalty/suggestions` |
| POST | `/api/agenda/me/businesses/{businessId}/loyalty/suggestions/{id}/send` |
| CRUD | `/api/agenda/me/businesses/{businessId}/notification-templates` |

### 4.3 Usuario final (cliente)
| Método | Ruta |
|---|---|
| GET | `/api/agenda/me/subscriptions` |
| POST | `/api/agenda/me/businesses/{businessId}/subscriptions` (comprar plan) |
| GET | `/api/agenda/me/bookings` |
| POST | `/api/agenda/me/businesses/{businessId}/bookings` (reservar) |
| DELETE | `/api/agenda/me/businesses/{businessId}/bookings/{id}` (cancelar) |

Documentación: **OpenAPI/Swagger desde el Sprint 1** (ver mejoras).

---

## 5. Feature flag (aislado dentro de AGENDA)

AGENDA gestiona sus propios flags **sin tocar el bot**. Replica el patrón de `BotFeatures`/`FeatureFlagService` pero dentro del paquete `com.botai.agenda`. Así la decisión de "totalmente independientes" se respeta al 100%.

```java
// com.botai.agenda.domain.feature
public enum AgendaFeatures {
    AGENDA_ENABLED,          // interruptor maestro por tenant
    PUBLIC_SEARCH_ENABLED,   // buscador público on/off
    LOYALTY_ENGINE_ENABLED,  // motor de fidelización
    AUTO_NOTIFICATIONS       // notificaciones automáticas
}

public interface AgendaFeatureFlagService {
    boolean isEnabled(AgendaFeatures feature, String tenantId);
}
```

- **Puerto:** `com.botai.agenda.domain.feature.AgendaFeatureFlagService`.
- **Implementación:** `com.botai.agenda.infrastructure.config.JpaAgendaFeatureFlagService`.
- **Persistencia:** tabla propia `agenda_tenant_config` (ver modelo de datos).
- **Guardia:** interceptor `AgendaFeatureGuard` en la capa REST que evalúa `AGENDA_ENABLED` para cada request autenticada bajo `/api/agenda/me/**`. Si el flag está off → **404 uniforme** (mejor que 403 para no revelar que el módulo existe).
- **Endpoints:** `/api/agenda/me/features` (GET/PUT) para que el admin prenda/apague flags de AGENDA sin exponer tenantId en URL.
- **Cero cambios en `com.botai.chatbot`** ni en `BotEntity` ni en `BotFeatures`.

---

## 6. Sprints (roadmap del documento respetado)

### Sprint 1 — Base de datos, Registro de Negocios y Buscador

**Objetivo:** Que un admin pueda registrar su negocio y que un usuario web sin login pueda buscarlo.

Entregables:
1. Tablas `agenda_*` + migraciones Flyway (ver mejora #1).
2. Entidades + puertos + adapters de: `Business`, `Service`, `BusinessSettings`, `Category`, `BusinessCategory` (pivote), `User` (modelo mínimo, sin auth todavía).
3. Endpoints Sprint 1 (registro de negocio, asociar categorías al negocio, búsqueda pública, CRUD de catálogo global de categorías).
4. `SynonymSearchAdapter` que resuelve primero contra `agenda_categories.synonyms` y luego contra `agenda_businesses.search_tags`.
5. Seed inicial de categorías comunes (`Peluquería`, `Manicure`, `Spa`, `Yoga`, `Gimnasio`, `Tatuajes`, ...) con sus sinónimos, en `V2__agenda_seed_categories.sql`.
6. Sistema de feature flags propio de AGENDA: enum `AgendaFeatures`, puerto `AgendaFeatureFlagService`, impl JPA sobre `agenda_tenant_config`, interceptor `AgendaFeatureGuard` y endpoints `GET/PUT /api/agenda/me/features`.
7. README del módulo AGENDA + configuración Swagger.
8. Tests unitarios de dominio + tests de integración con **Testcontainers PostgreSQL**.

**Historia cubierta:** "Búsqueda Inteligente".

### Sprint 2 — Planes, Compra y Billetera de Créditos

Entregables:
1. Entidades `Plan`, `UserSubscription`, `CreditTransaction`.
2. CRUD de planes por admin de negocio.
3. Caso de uso `PurchaseSubscription` (pago mockeado — stub de pagos para fase futura).
4. `CreditDomainService` con reglas de los 4 tipos de suscripción (`ILIMITADO_MENSUAL`, `POR_CREDITOS`, `SOLO_RESERVA`, `MIXTO`).
5. Endpoint "mi billetera" (saldo, vencimientos, historial de transacciones).
6. Tests de concurrencia de descuento (bloqueo pesimista).

**Historia cubierta:** "Control de Saldo".

### Sprint 3 — Reservas, Cancelación, Fidelización y Notificaciones

Entregables:
1. `BookingDomainService` + `CancellationDomainService`.
2. CU-01 (Proceso de Reserva Automatizada): descuento atómico + evento `BookingConfirmed`.
3. Política de cancelación configurable (`business_settings.hours_cancellation_limit`).
4. `LoyaltyDomainService` como `@EventListener` de `BookingConfirmed` — genera `LoyaltySuggestion`.
5. CU-02 (Notificación de Renovación): `@Scheduled` diario que evalúa vencimientos y saldos, crea notificaciones según `notification_templates`.
6. `NotificationPort` con implementación **in-app** (tabla `agenda_notifications`). Push/email queda stubbed.
7. Endpoints para panel de fidelización y plantillas.

**Historias cubiertas:** "Configuración de Alertas" + CU-01 + CU-02 + RF02, RF03, RF04, RF05, RF06.

---

## 7. Cobertura de requerimientos

| ID | Requerimiento | Sprint | Dónde |
|---|---|---|---|
| RF01 | Buscador por sinónimos | 1 | `SynonymSearchAdapter` |
| RF02 | Descuento automático al reservar | 3 | `BookingDomainService.confirmar` + `CreditDomainService.descontar` |
| RF03 | Penalización por cancelación tardía | 3 | `CancellationDomainService` |
| RF04 | Panel de fidelización | 3 | `LoyaltyDomainService` + endpoint |
| RF05 | Notificaciones configurables (stock + vencimiento + fidelización) | 3 | `@Scheduled` + `NotificationPort` + templates |
| RF06 | No reservas sin disponibilidad | 3 | `BookingDomainService.validarDisponibilidad` |
| RNF01 | Búsqueda pública sin login | 1 | `/api/agenda/public/**` + SecurityConfig |
| RNF02 | Múltiples suscripciones por usuario | 2 | `user_subscriptions` sin unique (user_id) |

Casos de uso CU-01 y CU-02 cubiertos en Sprint 3.

Clases del "Diagrama de clases de negocio" mapeadas:
- `Buscador.buscarPorSinonimo` → `SearchBusinessesUseCase`
- `Suscripcion.descontarCredito` / `validarVencimiento` → `CreditDomainService`
- `Notificador.ejecutarRegla` → `NotificationDomainService` + `NotificationPort`
- `Reserva.confirmar` / `cancelarConPenalizacion` → `BookingDomainService` + `CancellationDomainService`

---

## 8. Mejoras sugeridas (aportes al documento)

Todas son **opcionales**, propongo cuáles valen la pena ahora y cuáles se dejan como backlog.

### Ahora (Sprint 1)
1. **Migraciones con Flyway** en lugar de `ddl-auto: update`. El bot hoy usa `update`, pero AGENDA debería arrancar con migraciones versionadas (`V1__agenda_schema.sql`, `V2__agenda_seed.sql`...). Hibernate sigue en `validate` para AGENDA. Reduce riesgo de drift y hace los rollbacks posibles.
2. **OpenAPI/Swagger** (`springdoc-openapi-starter-webmvc-ui`). El documento indica que habrá app Flutter y web directorio: contratos OpenAPI desde el día 1 destraban al equipo frontend.
3. **Auditoría básica** (`@CreatedDate`, `@LastModifiedDate`, `@CreatedBy` con Spring Data auditing) en todas las entidades. El documento pide trazabilidad.
4. **Soft delete** (`deleted_at`) en `businesses`, `services`, `plans` en vez de borrado físico. Un negocio que se da de baja puede tener bookings históricos referenciándolo.
5. **Validación Bean Validation** estricta en DTOs (`@NotBlank`, `@Positive`, `@Future` para fechas de reserva).

### Pronto (Sprint 2–3)
6. **Pattern "Outbox" para eventos** (`agenda_outbox_events` + worker): `BookingConfirmed` y `CreditDebited` se persisten en la misma tx que la reserva y se publican después. Garantiza consistencia eventual con notificaciones/loyalty sin acoplar.
7. **Idempotencia de reservas**: header `Idempotency-Key` en POST `/bookings` — evita reservas duplicadas por reintentos de red.
8. **Rate limiting** en el buscador público (`/api/agenda/public/search`) con `bucket4j`. RNF01 dice "público sin login" y eso es un vector de abuso.
9. **Caché de búsqueda** (`@Cacheable` con TTL corto + invalidación al actualizar `search_tags`). El buscador será la landing: conviene cachear.
10. **Métricas de negocio** vía Micrometer: `agenda.bookings.confirmed`, `agenda.credits.debited`, `agenda.loyalty.triggered`. Útiles para un dashboard.

### Backlog (fuera de este plan)
11. **Jerarquía de categorías**: agregar `parent_category_id` en `agenda_categories` para permitir subcategorías (ej. `Belleza` → `Manicure`, `Pedicure`, `Maquillaje`). No se incluye en Sprint 1 para no sobrediseñar; la tabla queda plana.
12. **Extensión por tenant de categorías**: si un tenant necesita una categoría que no está en el catálogo global, hoy se resuelve sumándola al catálogo global. A futuro se podría permitir categorías "privadas" por tenant con `tenant_id` nullable.
13. **Motor de sinónimos aprendido**: entrenar/afinar con los logs de búsqueda reales. O reutilizar pgvector del bot para búsqueda semántica.
14. **Pagos reales** (Stripe/MercadoPago) detrás de `PaymentPort`.
15. **Push notifications** con FCM detrás de la `NotificationPort` ya diseñada.
16. **Webhook / API pública** para integrar con otros canales.
17. **Bridge opcional bot ↔ AGENDA** (futuro): si más adelante quieres que el bot del chat consulte créditos o reserve, se agrega un `AgendaClientPort` en el módulo del bot que consuma el REST de AGENDA. Nada se acopla hoy; solo es un puente opcional el día de mañana.

---

## 9. Configuración (`application.yml`)

Bloque nuevo, no modifica el existente del bot:

```yaml
agenda:
  enabled: ${AGENDA_ENABLED:true}        # off global de seguridad
  db:
    table-prefix: agenda_                # convención — todas las @Table llevan este prefijo
  search:
    cache-ttl-seconds: 60
    rate-limit:
      requests-per-minute: 60
  booking:
    default-cancellation-hours: 4
  loyalty:
    default-min-attendances: 3
    default-window-days: 30
  notifications:
    scheduled-cron: "0 0 9 * * *"        # revisión diaria 9am
```

`application-local.yml` quedará intocado para el bot; se agrega override de `agenda.*` si hace falta.

---

## 10. Testing

- **Unit tests** de `*DomainService` con JUnit 5 + Mockito (sin Spring).
- **Integration tests** con `@SpringBootTest` + **Testcontainers PostgreSQL** (imagen `postgres:16`) — Flyway crea las tablas `agenda_*` reales en el schema `public`.
- **Contract tests** REST con `MockMvc` + snapshots.
- **Concurrencia**: test específico que dispara 50 reservas simultáneas sobre la misma suscripción y verifica que no se sobregira el saldo.

Target cobertura mínimo: **80% en domain**, **60% global**.

---

## 11. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Conflicto de `@EntityScan` con el bot cuando se suman entidades AGENDA | Scans explícitos por módulo + test de arranque que verifica ambos contextos |
| Colisión de nombres de tabla al compartir schema `public` | **Prefijo obligatorio `agenda_`** en todas las `@Table` de AGENDA + test ArchUnit que valida la convención + revisión en PR |
| `ddl-auto: update` podría alterar tablas AGENDA no deseadamente | Adoptar **Flyway solo para AGENDA** (mejora #1) con `hibernate.ddl-auto=validate` para esas entidades; el bot sigue con `update` sobre sus tablas sin prefijo |
| Concurrencia en descuento de créditos | Bloqueo pesimista (`SELECT ... FOR UPDATE`) + tests de carga |
| Búsqueda pública expuesta → abuso | Rate limit + CORS explícito + no retornar PII |
| Crecimiento rápido de `credit_transactions` y `bookings` | Particionamiento por mes cuando supere volumen (decisión tardía, no bloqueante) |
| Divergencia futura bot ↔ AGENDA si llegaran a cruzarse | Mantener regla ArchUnit: prohibido importar entre paquetes hasta que se introduzca un `AgendaClientPort` explícito |

---

## 12. README del módulo (a crear en el Sprint 1)

Ubicación propuesta: `backend/src/main/java/com/botai/agenda/README.md` (o `backend/docs/AGENDA.md`). Contenido:

- Visión del módulo
- Diagrama de paquetes
- Cómo correr Flyway solo para tablas con prefijo `agenda_` (mismo schema `public`)
- Cómo habilitar/deshabilitar el módulo (flag + env vars)
- Configuración LLM relacionada (aunque AGENDA no usa LLM en esta fase, se documenta cómo integrarlo vía `AgendaClientPort` a futuro — tal como pide el documento)
- Convenciones de testing
- Cómo añadir una nueva regla de fidelización

---

## 13. Qué NO incluye este plan

- Frontend web (buscador público) ni app Flutter.
- Integración de pagos reales.
- Push notifications reales.
- Refactor o modificación de `BookAppointmentAction`, `ViewAppointmentsAction`, `AgendarTools` del bot.
- Migración del bot a Flyway (queda como sugerencia independiente).

---

## 14. Checklist antes de arrancar Sprint 1

- [ ] Aprobar este plan.
- [ ] Confirmar convención: schema único `public` + prefijo `agenda_` en todas las tablas del módulo.
- [ ] Confirmar prefijo de endpoints (`/api/agenda/**`).
- [ ] Decidir si se adopta Flyway solo para AGENDA (recomendado) o se pospone.
- [ ] Decidir si se añade Swagger/OpenAPI en Sprint 1 (recomendado).
- [ ] Crear tarjetas en Azure DevOps con las 3 historias de usuario del documento + las derivadas del Sprint 1.

---

**Siguiente paso sugerido:** revisar este plan, marcar los puntos en rojo, y cuando quieras arranco con el Sprint 1 — empezando por el scaffolding del paquete `com.botai.agenda`, la migración V1 creando las tablas `agenda_*` en el schema `public`, y las entidades `Business` + `Service` con sus endpoints y tests.
