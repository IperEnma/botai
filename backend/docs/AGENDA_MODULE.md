# Módulo AGENDA — Documentación completa del backend

> Sprints 1, 2 y 3 implementados y verdes. Este documento es la referencia operativa del módulo.
> Para el plan técnico y decisiones de arquitectura ver [PLAN_AGENDA.md](../../PLAN_AGENDA.md).

---

## Tabla de contenidos

1. [Requisitos previos](#1-requisitos-previos)
2. [Levantar la aplicación](#2-levantar-la-aplicación)
3. [Variables de entorno](#3-variables-de-entorno)
4. [Correr los tests](#4-correr-los-tests)
5. [Migraciones Flyway](#5-migraciones-flyway)
6. [Endpoints — referencia completa](#6-endpoints--referencia-completa)
   - [Públicos (sin login)](#61-públicos-sin-login)
   - [Platform admin — catálogo global](#62-platform-admin--catálogo-global)
   - [Tenant admin — feature flags](#63-tenant-admin--feature-flags)
   - [Tenant admin — negocios](#64-tenant-admin--negocios)
   - [Tenant admin — servicios](#65-tenant-admin--servicios)
   - [Tenant admin — planes](#66-tenant-admin--planes)
   - [Tenant admin — loyalty](#67-tenant-admin--loyalty)
   - [Tenant admin — plantillas de notificación](#68-tenant-admin--plantillas-de-notificación)
   - [Usuario final — suscripciones](#69-usuario-final--suscripciones)
   - [Usuario final — reservas](#610-usuario-final--reservas)
   - [Usuario final — notificaciones](#611-usuario-final--notificaciones)
7. [Swagger UI](#7-swagger-ui)
8. [Arquitectura y estructura de paquetes](#8-arquitectura-y-estructura-de-paquetes)
9. [Base de datos — tablas agenda_*](#9-base-de-datos--tablas-agenda_)
10. [Feature flags](#10-feature-flags)
11. [Comportamiento del motor de fidelización](#11-comportamiento-del-motor-de-fidelización)
12. [Reglas de cancelación y créditos](#12-reglas-de-cancelación-y-créditos)
13. [Outbox e idempotencia](#13-outbox-e-idempotencia)
14. [Convenciones de código](#14-convenciones-de-código)

---

## 1. Requisitos previos

| Herramienta | Versión mínima | Para qué |
|---|---|---|
| Java JDK | 17 | Compilar y correr el backend |
| Maven | 3.8 | Build y tests |
| Docker Desktop | cualquier reciente | PostgreSQL local + tests de integración |
| PostgreSQL | 16 (vía Docker) | Base de datos |

Verificar instalaciones:

```bash
java -version       # debe decir 17.x
mvn -version        # debe decir 3.8.x o mayor
docker info         # debe conectar sin errores
```

---

## 2. Levantar la aplicación

### Paso 1 — base de datos

```bash
# Desde la raíz del repo
docker-compose up -d postgres
```

Esto levanta PostgreSQL 16 en el puerto 5432. El módulo AGENDA usa el **mismo schema `public`** que el bot, pero sus tablas llevan el prefijo `agenda_`.

### Paso 2 — backend

```bash
cd backend
mvn spring-boot:run
```

Spring Boot arranca en el puerto **8080**. Al iniciar, Flyway ejecuta automáticamente las migraciones de `db/migration/agenda/` y crea todas las tablas `agenda_*`.

### Verificar que levantó

```bash
curl http://localhost:8080/actuator/health
# Respuesta esperada: {"status":"UP"}

curl "http://localhost:8080/api/agenda/public/categories"
# Devuelve la lista de categorías sembradas (peluquería, manicure, spa, etc.)
```

### Levantar solo para compilar (sin correr)

```bash
cd backend
mvn compile
# Si no hay errores, el módulo AGENDA no rompió ninguna clase del bot
```

---

## 3. Variables de entorno

Todas tienen valor por defecto; solo sobreescribir en producción.

| Variable | Default | Descripción |
|---|---|---|
| `AGENDA_ENABLED` | `true` | Interruptor global del módulo. Si `false`, todos los endpoints bajo `/api/agenda/tenants/**` y `/api/agenda/me/**` devuelven 404. |
| `AGENDA_PAYMENT_STUB_AUTO_APPROVE` | `true` | El adaptador de pagos es un stub. `true` aprueba todo; `false` rechaza todo (útil para probar el unhappy path). |
| `AGENDA_PAYMENT_STUB_REJECT_OVER` | `0` | Si > 0, rechaza pagos cuyo monto supere este valor. `0` = sin límite. |
| `AGENDA_IT` | _(no seteada)_ | Si se setea a `true`, habilita los tests de integración con Testcontainers. Requiere Docker. |

Ejemplo de uso en bash:

```bash
AGENDA_ENABLED=false mvn spring-boot:run   # arranca con el módulo deshabilitado
AGENDA_IT=true mvn test                    # corre también los integration tests
```

En PowerShell:

```powershell
$env:AGENDA_ENABLED = "false"; mvn spring-boot:run
$env:AGENDA_IT = "true"; mvn test
```

---

## 4. Correr los tests

### Solo tests unitarios de AGENDA (sin Docker)

```bash
cd backend
mvn test -Dtest='com.botai.agenda.**'
```

Corre los 210 tests unitarios de dominio, casos de uso, feature guard y scheduler. No necesita Docker ni base de datos.

**Resultado esperado:** `Tests run: 210, Failures: 0, Errors: 0, Skipped: 46`
(los 46 skipped son los tests de integración que requieren Docker)

### Tests de integración con Docker

```bash
cd backend

# bash
AGENDA_IT=true mvn test -Dtest='com.botai.agenda.**'

# PowerShell
$env:AGENDA_IT = "true"; mvn test -Dtest='com.botai.agenda.**'
```

Levanta un PostgreSQL 16 en Testcontainers, corre Flyway, y ejecuta los tests de integración contra la base real.

**Resultado esperado:** `Tests run: 256, Failures: 0, Errors: 0, Skipped: 0`

### Tests de concurrencia

El test `CreateBookingConcurrencyIntegrationTest` lanza 20 reservas simultáneas sobre la misma suscripción y verifica que el bloqueo pesimista (`SELECT ... FOR UPDATE`) impide que el saldo quede en negativo. Se incluye automáticamente con `AGENDA_IT=true`.

### Un test puntual

```bash
mvn test -Dtest=CreditDomainServiceTest
mvn test -Dtest=CreateBookingUseCaseTest
mvn test -Dtest=AgendaFeatureGuardTest
```

### Todos los tests del proyecto (bot + AGENDA)

```bash
cd backend
mvn test
```

---

## 5. Migraciones Flyway

Las migraciones de AGENDA viven en `backend/src/main/resources/db/migration/agenda/` y se ejecutan automáticamente al arrancar el backend.

| Archivo | Descripción |
|---|---|
| `V1__agenda_core_tables.sql` | Tablas base: businesses, users, categories, services, settings, tenant_config. Instala extensión `unaccent`. |
| `V2__agenda_seed_categories.sql` | Semilla de catálogo global: Peluquería, Manicure, Spa, Yoga, Gimnasio, Tatuajes, Pilates, Barbería, Nutrición, Estética y sus sinónimos en JSONB. |
| `V3__agenda_plans_and_subscriptions.sql` | Tablas: plans, user_subscriptions, credit_transactions. |
| `V4__agenda_bookings.sql` | Tabla bookings con índices de calendario. |
| `V5__agenda_plans_soft_delete.sql` | Agrega columna `deleted_at` a plans para soft delete. |
| `V6__agenda_bookings_slot_exclusion.sql` | Exclusión de solapamiento de slots por negocio/servicio. |
| `V7__agenda_loyalty_suggestions.sql` | Tabla loyalty_suggestions para el motor de fidelización. |
| `V8__agenda_notifications.sql` | Tablas notifications y notification_templates. |
| `V9__agenda_idempotency.sql` | Tabla idempotency_keys para evitar reservas duplicadas por reintento. |
| `V10__agenda_outbox.sql` | Tabla outbox_events para el patrón Outbox (publicación confiable de eventos). |

---

## 6. Endpoints — referencia completa

### Convenciones

- `{tenantId}` — identificador del tenant (string, ej. `"tenant-abc"`).
- `{businessId}` — UUID del negocio.
- Todos los endpoints bajo `/me/**` y `/tenants/**` leen el flag `AGENDA_ENABLED` del tenant. Si está en `false`, devuelven **404** (no 403).
- Los endpoints de usuario final requieren el header **`X-User-Id: <UUID>`**.
- Idempotencia en `POST /me/.../bookings`: enviar header `Idempotency-Key: <UUID>` para evitar duplicados en reintentos.

---

### 6.1 Públicos (sin login)

Base: `/api/agenda/public`

#### `GET /api/agenda/public/search`

Busca negocios por término. Resuelve sinónimos desde `agenda_categories.synonyms` y `agenda_businesses.search_tags`. Rate-limit: 60 req/min por IP.

**Query params:**
- `q` (requerido) — término de búsqueda
- `tenantId` (requerido) — limitar al tenant

```bash
curl "http://localhost:8080/api/agenda/public/search?q=uñas&tenantId=tenant-abc"
```

```json
[
  {
    "id": "3f2504e0-4f89-11d3-9a0c-0305e82c3301",
    "tenantId": "tenant-abc",
    "nombre": "Salón Belladonna",
    "descripcion": "Especialistas en uñas y nail art",
    "categorias": ["manicure"],
    "activo": true
  }
]
```

---

#### `GET /api/agenda/public/categories`

Devuelve el catálogo global de categorías con sus sinónimos. Usado para chips/filtros de UI.

```bash
curl "http://localhost:8080/api/agenda/public/categories"
```

```json
[
  {
    "id": "...",
    "nombre": "Manicure",
    "slug": "manicure",
    "synonyms": ["uñas", "uñitas", "nail art", "mani"],
    "activo": true
  }
]
```

---

#### `GET /api/agenda/public/categories/{slug}/businesses`

Lista negocios activos de una categoría, por tenant.

**Query params:**
- `tenantId` (requerido)

```bash
curl "http://localhost:8080/api/agenda/public/categories/manicure/businesses?tenantId=tenant-abc"
```

---

#### `GET /api/agenda/public/businesses/{id}`

Ficha pública de un negocio (incluye sus categorías asociadas).

```bash
curl "http://localhost:8080/api/agenda/public/businesses/3f2504e0-4f89-11d3-9a0c-0305e82c3301"
```

---

#### `GET /api/agenda/public/businesses/{id}/services`

Lista los servicios activos de un negocio (duración, precio).

```bash
curl "http://localhost:8080/api/agenda/public/businesses/3f2504e0-4f89-11d3-9a0c-0305e82c3301/services"
```

```json
[
  {
    "id": "...",
    "nombre": "Manicure semi-permanente",
    "duracionMin": 60,
    "precio": 3500.00,
    "activo": true
  }
]
```

---

### 6.2 Platform admin — catálogo global

Base: `/api/agenda/platform/categories`
Requiere rol `PLATFORM_ADMIN`. El admin de negocio **no puede crear** categorías, solo asociarlas.

#### `GET /api/agenda/platform/categories`

Lista todas las categorías del catálogo global.

```bash
curl http://localhost:8080/api/agenda/platform/categories
```

---

#### `POST /api/agenda/platform/categories`

Crea una categoría global nueva.

```bash
curl -X POST http://localhost:8080/api/agenda/platform/categories \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Reiki",
    "slug": "reiki",
    "synonyms": ["energia", "sanacion", "chakras"],
    "activo": true
  }'
```

---

#### `PUT /api/agenda/platform/categories/{id}`

Actualiza nombre, slug o estado de una categoría.

```bash
curl -X PUT http://localhost:8080/api/agenda/platform/categories/{id} \
  -H "Content-Type: application/json" \
  -d '{ "nombre": "Reiki & Energía", "slug": "reiki", "activo": true }'
```

---

#### `PUT /api/agenda/platform/categories/{id}/synonyms`

Agrega sinónimos a una categoría existente (merge, no reemplaza).

```bash
curl -X PUT http://localhost:8080/api/agenda/platform/categories/{id}/synonyms \
  -H "Content-Type: application/json" \
  -d '{ "synonyms": ["bio-energia", "aura"] }'
```

---

#### `DELETE /api/agenda/platform/categories/{id}`

Elimina una categoría del catálogo global (fallo con 409 si tiene negocios asociados).

```bash
curl -X DELETE http://localhost:8080/api/agenda/platform/categories/{id}
```

---

### 6.3 Tenant admin — feature flags

Base: `/api/agenda/tenants/{tenantId}/features`

#### `GET /api/agenda/tenants/{tenantId}/features`

Devuelve los flags de AGENDA activos para el tenant.

```bash
curl http://localhost:8080/api/agenda/tenants/tenant-abc/features
```

```json
{
  "tenantId": "tenant-abc",
  "agendaEnabled": true,
  "publicSearchEnabled": true,
  "loyaltyEngineEnabled": true,
  "autoNotifications": false
}
```

---

#### `PUT /api/agenda/tenants/{tenantId}/features`

Actualiza los flags. Los campos enviados como `null` no se modifican (semántica PATCH).

```bash
curl -X PUT http://localhost:8080/api/agenda/tenants/tenant-abc/features \
  -H "Content-Type: application/json" \
  -d '{
    "agendaEnabled": true,
    "publicSearchEnabled": true,
    "loyaltyEngineEnabled": true,
    "autoNotifications": true
  }'
```

---

### 6.4 Tenant admin — negocios

Base: `/api/agenda/tenants/{tenantId}/businesses`

#### `POST /api/agenda/tenants/{tenantId}/businesses`

Registra un negocio nuevo en el tenant. `searchTags` son keywords adicionales de búsqueda específicas del negocio.

```bash
curl -X POST http://localhost:8080/api/agenda/tenants/tenant-abc/businesses \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Salón Belladonna",
    "descripcion": "Especialistas en uñas y nail art",
    "ownerUserId": "a1b2c3d4-0000-0000-0000-000000000001",
    "searchTags": ["belladonna", "palermo", "nail art premium"]
  }'
```

```json
{
  "id": "3f2504e0-4f89-11d3-9a0c-0305e82c3301",
  "tenantId": "tenant-abc",
  "nombre": "Salón Belladonna",
  "descripcion": "Especialistas en uñas y nail art",
  "searchTags": ["belladonna", "palermo", "nail art premium"],
  "activo": true,
  "createdAt": "2026-04-22T10:00:00Z"
}
```

---

#### `GET /api/agenda/tenants/{tenantId}/businesses`

Lista todos los negocios del tenant.

```bash
curl http://localhost:8080/api/agenda/tenants/tenant-abc/businesses
```

---

#### `GET /api/agenda/tenants/{tenantId}/businesses/{businessId}`

Detalle de un negocio.

```bash
curl http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/3f2504e0-4f89-11d3-9a0c-0305e82c3301
```

---

#### `PUT /api/agenda/tenants/{tenantId}/businesses/{businessId}`

Actualiza datos del negocio. `activo: false` hace soft delete.

```bash
curl -X PUT http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId} \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Belladonna Studio",
    "descripcion": "Uñas, maquillaje y spa",
    "searchTags": ["belladonna", "palermo", "spa"],
    "activo": true
  }'
```

---

#### `PUT /api/agenda/tenants/{tenantId}/businesses/{businessId}/categories`

Reemplaza la lista completa de categorías asociadas al negocio. Enviar array de IDs del catálogo global.

```bash
curl -X PUT http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/categories \
  -H "Content-Type: application/json" \
  -d '{ "categoryIds": ["uuid-cat-manicure", "uuid-cat-spa"] }'
```

Responde `204 No Content`.

---

#### `GET /api/agenda/tenants/{tenantId}/businesses/{businessId}/settings`

Obtiene la configuración del negocio. Si no existe fila en DB devuelve los valores por defecto.

```bash
curl http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/settings
```

```json
{
  "businessId": "3f2504e0-4f89-11d3-9a0c-0305e82c3301",
  "hoursCancellationLimit": 4,
  "loyaltyMinAttendances": 3,
  "loyaltyWindowDays": 30,
  "expirationAlertDays": 7,
  "expirationAlertCredits": 2,
  "autoNotifyEnabled": true
}
```

---

#### `PUT /api/agenda/tenants/{tenantId}/businesses/{businessId}/settings`

Actualiza la configuración del negocio.

| Campo | Descripción |
|---|---|
| `hoursCancellationLimit` | Horas mínimas de anticipación para cancelar sin penalización |
| `loyaltyMinAttendances` | Asistencias mínimas para disparar sugerencia de plan |
| `loyaltyWindowDays` | Ventana de días en que se cuentan las asistencias |
| `expirationAlertDays` | Días antes del vencimiento para notificar |
| `expirationAlertCredits` | Umbral de saldo bajo para notificar |
| `autoNotifyEnabled` | Si el scheduler envía notificaciones automáticamente |

```bash
curl -X PUT http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/settings \
  -H "Content-Type: application/json" \
  -d '{
    "hoursCancellationLimit": 6,
    "loyaltyMinAttendances": 5,
    "loyaltyWindowDays": 60,
    "expirationAlertDays": 14,
    "expirationAlertCredits": 3,
    "autoNotifyEnabled": true
  }'
```

---

### 6.5 Tenant admin — servicios

Base: `/api/agenda/tenants/{tenantId}/businesses/{businessId}/services`

#### `GET .../services`

Lista los servicios del negocio. `soloActivos=true` filtra los dados de baja.

```bash
curl "http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/services?soloActivos=true"
```

---

#### `POST .../services`

Crea un servicio.

```bash
curl -X POST http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/services \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Manicure semi-permanente",
    "descripcion": "Duración 3 semanas",
    "duracionMin": 60,
    "precio": 3500.00
  }'
```

---

#### `PUT .../services/{serviceId}`

Actualiza un servicio. `activo: false` hace soft delete.

```bash
curl -X PUT http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/services/{serviceId} \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Manicure semi-permanente",
    "descripcion": "Duración 3 semanas. Incluye diseño.",
    "duracionMin": 75,
    "precio": 4000.00,
    "activo": true
  }'
```

---

#### `DELETE .../services/{serviceId}`

Baja lógica del servicio (soft delete, `activo=false`).

```bash
curl -X DELETE http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/services/{serviceId}
```

Responde `204 No Content`.

---

### 6.6 Tenant admin — planes

Base: `/api/agenda/tenants/{tenantId}/businesses/{businessId}/plans`

Los planes son lo que los clientes compran como suscripción. Hay 4 tipos:

| `tipo` | Comportamiento |
|---|---|
| `POR_CREDITOS` | El cliente tiene N créditos; cada reserva descuenta 1 |
| `ILIMITADO_MENSUAL` | Sin límite de reservas durante `validezDias` días |
| `SOLO_RESERVA` | Sin suscripción; el cliente paga por turno |
| `MIXTO` | Créditos + ilimitado según regla del negocio |

#### `POST .../plans`

```bash
curl -X POST http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/plans \
  -H "Content-Type: application/json" \
  -d '{
    "nombrePlan": "Pack 10 clases",
    "tipo": "POR_CREDITOS",
    "tier": "PLATA",
    "totalCreditos": 10,
    "validezDias": 90,
    "precio": 15000.00,
    "activo": true
  }'
```

Valores de `tier`: `VIP`, `GOLDEN`, `PLATA`.

---

#### `GET .../plans`

Lista planes. `onlyActive=true` filtra los dados de baja lógica.

```bash
curl "http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/plans?onlyActive=true"
```

---

#### `GET .../plans/{planId}`

Detalle de un plan.

---

#### `PUT .../plans/{planId}`

Actualiza un plan. Los campos enviados como `null` no se modifican.

```bash
curl -X PUT http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/plans/{planId} \
  -H "Content-Type: application/json" \
  -d '{
    "nombrePlan": "Pack 10 clases — Promo",
    "precio": 12000.00
  }'
```

---

#### `DELETE .../plans/{planId}`

Baja lógica del plan (`activo=false`). No se puede borrar físicamente si hay suscripciones activas.

```bash
curl -X DELETE http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/plans/{planId}
```

---

### 6.7 Tenant admin — loyalty

Base: `/api/agenda/tenants/{tenantId}/businesses/{businessId}/loyalty/suggestions`

El motor de fidelización genera sugerencias automáticamente cuando un usuario sin suscripción activa supera el umbral de asistencias configurado en `business_settings`.

#### `GET .../loyalty/suggestions`

Lista las sugerencias del negocio. Filtro opcional por `estado`: `PENDING`, `SENT`, `DISMISSED`.

```bash
curl "http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/loyalty/suggestions?estado=PENDING"
```

```json
[
  {
    "id": "...",
    "businessId": "...",
    "userId": "...",
    "triggerRule": "attendances>=3 in 30 days",
    "estado": "PENDING",
    "createdAt": "2026-04-22T09:00:00Z"
  }
]
```

---

#### `PATCH .../loyalty/suggestions/{suggestionId}`

Cambia el estado de una sugerencia (marcar como enviada manualmente o descartar).

```bash
curl -X PATCH http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/loyalty/suggestions/{suggestionId} \
  -H "Content-Type: application/json" \
  -d '{ "estado": "DISMISSED" }'
```

---

#### `POST .../loyalty/suggestions/{suggestionId}/send`

Envía la notificación in-app al usuario asociado a la sugerencia y cambia el estado a `SENT`.

```bash
curl -X POST http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/loyalty/suggestions/{suggestionId}/send
```

---

### 6.8 Tenant admin — plantillas de notificación

Base: `/api/agenda/tenants/{tenantId}/businesses/{businessId}/notification-templates`

Las plantillas definen los mensajes que el scheduler envía automáticamente (vencimientos, saldo bajo).

#### `GET .../notification-templates`

```bash
curl http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/notification-templates
```

---

#### `POST .../notification-templates`

```bash
curl -X POST http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/notification-templates \
  -H "Content-Type: application/json" \
  -d '{
    "codigo": "EXPIRATION_ALERT",
    "canal": "IN_APP",
    "titulo": "Tu plan vence pronto",
    "cuerpo": "Hola, tu suscripción vence en {dias} días. ¡Renovala antes de que pierda tus créditos!"
  }'
```

Valores de `canal`: `IN_APP`, `EMAIL`, `PUSH` (EMAIL y PUSH son stubs en esta fase).

---

#### `PUT .../notification-templates/{templateId}`

Actualiza una plantilla existente.

---

#### `DELETE .../notification-templates/{templateId}`

Elimina una plantilla.

```bash
curl -X DELETE http://localhost:8080/api/agenda/tenants/tenant-abc/businesses/{businessId}/notification-templates/{templateId}
```

---

### 6.9 Usuario final — suscripciones

Base: `/api/agenda/me`
Header requerido: `X-User-Id: <UUID>`

#### `POST /api/agenda/me/tenants/{tenantId}/businesses/{businessId}/subscriptions`

Compra una suscripción a un plan del negocio. El pago es procesado por el `StubPaymentAdapter` (aprueba todo por defecto).

```bash
curl -X POST http://localhost:8080/api/agenda/me/tenants/tenant-abc/businesses/{businessId}/subscriptions \
  -H "Content-Type: application/json" \
  -H "X-User-Id: a1b2c3d4-0000-0000-0000-000000000099" \
  -d '{ "planId": "uuid-del-plan" }'
```

```json
{
  "id": "sub-uuid",
  "userId": "a1b2c3d4-0000-0000-0000-000000000099",
  "planId": "uuid-del-plan",
  "businessId": "uuid-del-negocio",
  "saldoActual": 10,
  "fechaInicio": "2026-04-22",
  "fechaExpiracion": "2026-07-21",
  "estado": "ACTIVE"
}
```

---

#### `GET /api/agenda/me/subscriptions`

Lista todas las suscripciones del usuario. `onlyActive=true` filtra solo las activas.

```bash
curl "http://localhost:8080/api/agenda/me/subscriptions?onlyActive=true" \
  -H "X-User-Id: a1b2c3d4-0000-0000-0000-000000000099"
```

---

#### `GET /api/agenda/me/subscriptions/{subscriptionId}/wallet`

Detalle de la billetera: saldo actual + historial completo de movimientos de crédito.

```bash
curl http://localhost:8080/api/agenda/me/subscriptions/{subscriptionId}/wallet \
  -H "X-User-Id: a1b2c3d4-0000-0000-0000-000000000099"
```

```json
{
  "subscriptionId": "sub-uuid",
  "saldoActual": 8,
  "fechaExpiracion": "2026-07-21",
  "estado": "ACTIVE",
  "movimientos": [
    { "id": "...", "monto": 10, "motivo": "COMPRA", "createdAt": "2026-04-22T10:00:00Z" },
    { "id": "...", "monto": -1, "motivo": "RESERVA", "bookingId": "...", "createdAt": "2026-04-23T11:00:00Z" },
    { "id": "...", "monto": -1, "motivo": "RESERVA", "bookingId": "...", "createdAt": "2026-04-25T09:30:00Z" }
  ]
}
```

---

### 6.10 Usuario final — reservas

Base: `/api/agenda/me`
Header requerido: `X-User-Id: <UUID>`

#### `POST /api/agenda/me/tenants/{tenantId}/businesses/{businessId}/bookings`

Crea una reserva confirmada. Si el usuario tiene una suscripción activa, descuenta 1 crédito de forma atómica (con bloqueo pesimista). Si `subscriptionId` es `null`, se crea como modo `SOLO_RESERVA`.

Header opcional: `Idempotency-Key: <UUID>` para evitar duplicados en reintentos de red.

```bash
curl -X POST http://localhost:8080/api/agenda/me/tenants/tenant-abc/businesses/{businessId}/bookings \
  -H "Content-Type: application/json" \
  -H "X-User-Id: a1b2c3d4-0000-0000-0000-000000000099" \
  -H "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000" \
  -d '{
    "serviceId": "uuid-del-servicio",
    "subscriptionId": "sub-uuid",
    "fechaHoraInicio": "2026-05-10T10:00:00",
    "notas": "Quiero diseño floral"
  }'
```

```json
{
  "id": "booking-uuid",
  "userId": "a1b2c3d4-0000-0000-0000-000000000099",
  "serviceId": "uuid-del-servicio",
  "businessId": "uuid-del-negocio",
  "subscriptionId": "sub-uuid",
  "fechaHoraInicio": "2026-05-10T10:00:00",
  "fechaHoraFin": "2026-05-10T11:00:00",
  "estado": "CONFIRMED",
  "tipoReserva": "SUBSCRIPTION"
}
```

**Errores posibles:**
- `409 SLOT_TAKEN` — el horario ya está ocupado para ese servicio/negocio.
- `422 NO_CREDITS` — la suscripción no tiene saldo suficiente.
- `422 SUBSCRIPTION_EXPIRED` — la suscripción venció.

---

#### `GET /api/agenda/me/tenants/{tenantId}/businesses/{businessId}/bookings`

Lista mis reservas en un negocio. Filtro opcional por `estado`: `SCHEDULED`, `CONFIRMED`, `CANCELLED`, `COMPLETED`, `NO_SHOW`.

```bash
curl "http://localhost:8080/api/agenda/me/tenants/tenant-abc/businesses/{businessId}/bookings?estado=CONFIRMED" \
  -H "X-User-Id: a1b2c3d4-0000-0000-0000-000000000099"
```

---

#### `DELETE /api/agenda/me/tenants/{tenantId}/businesses/{businessId}/bookings/{bookingId}`

Cancela una reserva. Si se cancela dentro de la ventana de cancelación (`hoursCancellationLimit` horas de anticipación), devuelve el crédito. Si se cancela fuera de la ventana, el crédito se pierde (penalización).

```bash
curl -X DELETE http://localhost:8080/api/agenda/me/tenants/tenant-abc/businesses/{businessId}/bookings/{bookingId} \
  -H "X-User-Id: a1b2c3d4-0000-0000-0000-000000000099"
```

**Errores posibles:**
- `409 BOOKING_NOT_CANCELLABLE` — la reserva ya fue completada o cancelada.

---

### 6.11 Usuario final — notificaciones

#### `GET /api/agenda/me/notifications`

Lista las notificaciones in-app del usuario. Filtro opcional por `estado`: `PENDING`, `SENT`, `READ`.

```bash
curl "http://localhost:8080/api/agenda/me/notifications?estado=PENDING" \
  -H "X-User-Id: a1b2c3d4-0000-0000-0000-000000000099"
```

```json
[
  {
    "id": "...",
    "businessId": "...",
    "canal": "IN_APP",
    "titulo": "Tu plan vence pronto",
    "cuerpo": "Hola, tu suscripción vence en 7 días.",
    "estado": "PENDING",
    "createdAt": "2026-04-22T09:00:00Z"
  }
]
```

---

## 7. Swagger UI

Al arrancar el backend se expone la documentación interactiva OpenAPI:

```
http://localhost:8080/swagger-ui.html
```

Los endpoints de AGENDA aparecen bajo el grupo **"agenda"** (separado de los del bot). Desde ahí se puede probar cada endpoint directamente con el botón "Try it out".

---

## 8. Arquitectura y estructura de paquetes

```
com.botai.agenda
├── AgendaModuleConfig.java            # @Configuration, @ComponentScan limitado al módulo
│
├── domain/
│   ├── context/        AgendaTenantContext (ThreadLocal multi-tenant)
│   ├── event/          Eventos de dominio (BookingConfirmedEvent)
│   ├── exception/      Excepciones tipadas (extienden AgendaDomainException)
│   ├── feature/        AgendaFeatures enum + AgendaFeatureFlagService (puerto)
│   ├── model/          POJOs inmutables de negocio
│   ├── notification/   NotificationPort (puerto de notificaciones)
│   ├── repository/     Puertos (interfaces *Repository)
│   └── service/        Servicios de dominio (BookingDomainService, CreditDomainService, etc.)
│
├── application/
│   ├── dto/            Request / Response
│   ├── mapper/         DTO ↔ Domain
│   └── usecase/        Casos de uso (@Service, sin Spring en unit tests)
│
└── infrastructure/
    ├── api/            @RestController + AgendaGlobalExceptionHandler
    ├── config/         Flyway, WebMVC, OpenAPI, AgendaFeatureGuard,
    │                   AgendaRateLimitInterceptor, AgendaIdempotencyFilter,
    │                   AgendaCacheConfig, JpaAgendaFeatureFlagService
    ├── event/          BookingConfirmedEventListener (@EventListener)
    ├── notification/   InAppNotificationAdapter
    ├── payment/        StubPaymentAdapter
    ├── persistence/
    │   ├── entity/     @Entity con @Table(name="agenda_*") + BaseAuditableEntity
    │   ├── jpa/        *JpaRepository (Spring Data) + Jpa*Repository (adapter)
    │   └── mapper/     Entity ↔ Domain
    ├── scheduler/      ExpirationCheckScheduler (CU-02), OutboxEventScheduler,
    │                   IdempotencyCleanupScheduler
    └── search/         SynonymSearchAdapter
```

**Regla de oro:** ningún archivo de `com.botai.agenda` puede importar clases de `com.botai.chatbot` y viceversa.

---

## 9. Base de datos — tablas agenda_*

Todas las tablas conviven en el schema `public` con prefijo `agenda_`. Hibernate está en modo `validate` para estas tablas (Flyway es la única fuente de verdad del schema).

| Tabla | Descripción |
|---|---|
| `agenda_users` | Usuarios del módulo (independiente de los leads del bot) |
| `agenda_businesses` | Negocios por tenant, con soft delete |
| `agenda_categories` | Catálogo global de categorías con sinónimos JSONB |
| `agenda_business_categories` | Pivote N:M negocios-categorías |
| `agenda_services` | Servicios por negocio |
| `agenda_business_settings` | Configuración por negocio (cancelación, loyalty, alertas) |
| `agenda_plans` | Planes de suscripción que vende el negocio |
| `agenda_user_subscriptions` | Billetera del usuario por negocio (saldo + vencimiento) |
| `agenda_credit_transactions` | Historial inmutable de movimientos de crédito |
| `agenda_bookings` | Citas confirmadas o pendientes |
| `agenda_loyalty_suggestions` | Sugerencias generadas por el motor de fidelización |
| `agenda_notifications` | Notificaciones in-app recibidas por el usuario |
| `agenda_notification_templates` | Plantillas editables por el admin del negocio |
| `agenda_tenant_config` | Feature flags y configuración de AGENDA por tenant |
| `agenda_outbox_events` | Cola de eventos para publicación confiable (patrón Outbox) |
| `agenda_idempotency_keys` | Claves de idempotencia para POST /bookings |

---

## 10. Feature flags

AGENDA tiene su propio sistema de flags, completamente aislado del bot.

| Flag (`AgendaFeatures`) | Descripción |
|---|---|
| `AGENDA_ENABLED` | Interruptor maestro del tenant. Si está `false`, el guard devuelve 404 en todos los endpoints sensibles. |
| `PUBLIC_SEARCH_ENABLED` | Habilita el buscador público (`/api/agenda/public/search`). |
| `LOYALTY_ENGINE_ENABLED` | Activa el motor que genera sugerencias de fidelización. |
| `AUTO_NOTIFICATIONS` | El scheduler diario envía notificaciones automáticamente. |

El guard `AgendaFeatureGuard` se aplica a todos los endpoints bajo `/api/agenda/tenants/**` y `/api/agenda/me/**`. Devuelve **404 uniforme** (no 403) para no revelar que el módulo existe cuando está deshabilitado.

---

## 11. Comportamiento del motor de fidelización

El motor se activa automáticamente cuando ocurre el evento `BookingConfirmedEvent`:

1. Cuenta las reservas completadas del usuario en el negocio dentro de los últimos `loyaltyWindowDays` días.
2. Si el conteo supera `loyaltyMinAttendances` **y** el usuario no tiene suscripción activa, crea una `LoyaltySuggestion` en estado `PENDING`.
3. Si `LOYALTY_ENGINE_ENABLED=false` para el tenant, el listener no hace nada.
4. Si `autoNotifyEnabled=true` en `business_settings`, la sugerencia se envía inmediatamente como notificación in-app.

El scheduler diario (`ExpirationCheckScheduler`) corre a las 9 AM y, adicionalmente, revisa suscripciones próximas a vencer y saldos bajos para generar notificaciones según los umbrales de `business_settings`.

---

## 12. Reglas de cancelación y créditos

### Cancelación gratuita
`ahora + hoursCancellationLimit <= fechaHoraInicio` → el crédito se devuelve.

### Cancelación con penalización
Si se cancela fuera de la ventana → el crédito **no** se devuelve. Se registra igual en `agenda_credit_transactions` con motivo `CANCELACION_PENALIZADA`.

### Tipos de suscripción y lógica de descuento

| Tipo | Al reservar | Al cancelar dentro de ventana |
|---|---|---|
| `POR_CREDITOS` | Descuenta 1 crédito | Devuelve 1 crédito |
| `ILIMITADO_MENSUAL` | Registra transacción con monto 0 (trazabilidad) | Sin crédito que devolver |
| `SOLO_RESERVA` | Sin suscripción, sin descuento | Sin crédito que devolver |
| `MIXTO` | Descuenta según la regla del plan | Devuelve si corresponde |

El descuento es **atómico**: la fila de `agenda_user_subscriptions` se bloquea con `SELECT ... FOR UPDATE` durante la transacción para evitar double-spend en reservas concurrentes.

---

## 13. Outbox e idempotencia

### Outbox
Los eventos de dominio (`BookingConfirmedEvent`, etc.) se persisten en `agenda_outbox_events` dentro de la misma transacción que la reserva, y el `OutboxEventScheduler` los publica al `ApplicationEventPublisher` cada 10 segundos. Esto garantiza que el evento siempre se procesa aunque falle el listener la primera vez.

### Idempotencia
El `AgendaIdempotencyFilter` intercepta los `POST` a `/api/agenda/me/.../bookings`. Si recibe un header `Idempotency-Key`, almacena la respuesta en `agenda_idempotency_keys` (TTL 24h) y la repite en reintentos con el mismo key. Así un reintento de red no crea dos reservas.

Las claves vencidas se limpian por `IdempotencyCleanupScheduler` diariamente.

---

## 14. Convenciones de código

| Capa | Convención | Ejemplo |
|---|---|---|
| Dominio (POJO) | Sustantivo del dominio | `Booking`, `Plan` |
| Puerto | `<Nombre>Repository` o `<Nombre>Port` | `BookingRepository` |
| Adapter JPA | `Jpa<Nombre>Repository` | `JpaBookingRepository` |
| Spring Data | `<Nombre>JpaRepository` | `BookingJpaRepository` |
| Entity JPA | `<Nombre>Entity` + `@Table(name = "agenda_<plural>")` | `BookingEntity` → `agenda_bookings` |
| Caso de uso | Verbo+Nombre+`UseCase` | `CreateBookingUseCase` |
| Controller | `<Recurso>Controller` | `MeBookingsController` |
| DTO Request | `Create/Update<Recurso>Request` | `CreateBookingRequest` |
| DTO Response | `<Recurso>Response` | `BookingResponse` |
| Migración | `V<N>__agenda_<descripcion>.sql` | `V4__agenda_bookings.sql` |
