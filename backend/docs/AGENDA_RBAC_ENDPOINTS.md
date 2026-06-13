# Mapeo Endpoint → Rol — Konecta Agenda

**Propósito.** Este documento es la fuente única de verdad para la fase de implementación de RBAC. Cada endpoint del backend está clasificado por roles autorizados y restricciones de scope. La capa de autorización (Spring Security / `@PreAuthorize`) deberá implementar exactamente lo aquí declarado.

**Estado.** Fase 0 del proyecto RBAC (ver `AGENDA_RBAC_PLAN.md` para fases siguientes). Ningún endpoint está hoy protegido por anotaciones de Spring; las únicas defensas actuales son la resolución de `tenantId` vía email del JWT y `requireBusinessOwnedByCurrentTenant()`. Las columnas de roles describen el **estado objetivo**.

---

## Roles

| Código | Rol | Scope |
|--------|-----|-------|
| **PA** | `PLATFORM_ADMIN` | Plataforma (global, fuera de tenant) |
| **OW** | `OWNER` | Tenant completo. Un único OWNER por tenant. |
| **TA** | `TENANT_ADMIN` | Tenant completo, con restricciones (no transfiere propiedad, no borra workspace, no crea admins). |
| **RC** | `RECEPTION` | Una o varias sucursales asignadas. |
| **SV** | `STAFF_VIEWER` | Una o varias sucursales. Solo su propia agenda. |
| **SO** | `STAFF_OPERATOR` | Una o varias sucursales. Solo su propia agenda + crear/modificar reservas propias. |
| **CL** | `CLIENT` | Reservas propias en negocios públicos. Identificación vía sesión OTP. |
| **PUB** | (sin autenticación) | Endpoints públicos, sin token. |

> **STAFF sin cuenta** no aparece como rol autorizable: es un `StaffMember` cuyo `userId` es `NULL`. No accede a la API.

## Convenciones de la tabla

| Símbolo | Significado |
|---------|-------------|
| ✓ | Acceso permitido sin restricción adicional dentro del scope del rol. |
| ✓ⓑ | Acceso permitido **limitado a las sucursales asignadas** (aplica a RC, SV, SO). |
| ✓ⓞ | Acceso permitido **solo sobre recursos propios** (own booking, own agenda, own profile). |
| (vacío) | No autorizado. |

## Códigos de autenticación

| Código | Significado |
|--------|-------------|
| **❌** | Sin autenticación (endpoint público). |
| **🔑** | JWT Google ID token (header `Authorization: Bearer …`). Resuelve usuario y tenant vía email. |
| **🎫** | Token de sesión OTP del cliente público (header propio). No es JWT Google. |
| **🔧** | Webhook con secreto/verify-token. No tiene "usuario". |

## Restricciones (columna final)

| Código | Significado |
|--------|-------------|
| **T** | Tenant scope: el recurso debe pertenecer al tenant del usuario. |
| **B** | Business scope: si el usuario es RC/SV/SO, el `businessId` del path debe estar entre sus sucursales asignadas. |
| **O** | Ownership: si el usuario es SV/SO, el recurso operado debe pertenecerle (own booking/agenda). Si el usuario es CL, la reserva debe ser suya. |
| **—** | Sin restricción adicional al rol. |

---

## 1. Endpoints públicos — `/api/agenda/public/**`

Sin autenticación o autenticados solo por sesión OTP del cliente final.

| Método | Endpoint | Auth | Autorizados | Restr. | Notas |
|--------|----------|------|-------------|--------|-------|
| GET | `/api/agenda/public/search` | ❌ | PUB | — | Buscador público de negocios. |
| GET | `/api/agenda/public/categories` | ❌ | PUB | — | Listado de categorías activas. |
| GET | `/api/agenda/public/categories/{slug}/businesses` | ❌ | PUB | — | Negocios por categoría. |
| GET | `/api/agenda/public/businesses/{id}` | ❌ | PUB | — | Ficha pública. |
| GET | `/api/agenda/public/businesses/{id}/services` | ❌ | PUB | — | Servicios activos. |
| GET | `/api/agenda/public/businesses/{businessId}/staff` | ❌ | PUB | — | Profesionales visibles públicamente (incluye STAFF sin cuenta). |
| GET | `/api/agenda/public/businesses/{businessId}/hours` | ❌ | PUB | — | Horarios publicados. |
| GET | `/api/agenda/public/businesses/{businessId}/availability` | ❌ | PUB | — | Slots disponibles. |
| GET | `/api/agenda/public/businesses/by-slug/{slug}` | ❌ | PUB | — | Ficha por slug. |
| GET | `/api/agenda/public/businesses/by-slug/{slug}/services` | ❌ | PUB | — | Servicios por slug. |
| GET | `/api/agenda/public/businesses/by-slug/{slug}/staff` | ❌ | PUB | — | Equipo por slug. |
| GET | `/api/agenda/public/businesses/by-slug/{slug}/hours` | ❌ | PUB | — | Horarios por slug. |
| GET | `/api/agenda/public/businesses/by-slug/{slug}/photos` | ❌ | PUB | — | Fotos publicadas. |
| GET | `/api/agenda/public/businesses/by-slug/{slug}/availability` | ❌ | PUB | — | Slots por slug. |
| GET | `/api/agenda/public/address/geocode` | ❌ | PUB | — | Geocoder público (usado por buscador). |
| GET | `/api/agenda/public/map-preview` | ❌ | PUB | — | PNG OSM. |
| GET | `/api/agenda/public/media/{*relativePath}` | ❌ | PUB | — | Sirve uploads. Validación de path traversal en código. |
| GET | `/api/agenda/public/companies/{companySlug}` | ❌ | PUB | — | Marca y sucursales activas. |
| GET | `/api/agenda/public/links/{slug}` | ❌ | PUB | — | Resuelve slug → businessId. |
| POST | `/api/agenda/public/businesses/{businessId}/phone-verification/send` | ❌ | PUB | — | Envía OTP por WhatsApp. Rate-limited. |
| POST | `/api/agenda/public/businesses/{businessId}/phone-verification/verify` | ❌ | PUB | — | Valida OTP y emite token de sesión (🎫). |
| GET | `/api/agenda/public/tenants/by-code/{accessCode}` | ❌ | PUB | — | Resolución de tenant por código de acceso (onboarding). |
| POST | `/api/agenda/public/register` | ❌ | PUB | — | Registra tenant + business desde landing. |
| POST | `/api/agenda/public/businesses/{businessId}/reviews` | 🎫 | CL | O | Reseña sobre reserva COMPLETADA del cliente. |
| POST | `/api/agenda/public/businesses/{businessId}/bookings` | 🎫 | CL | O | Crea reserva como cliente final identificado por OTP. |
| GET | `/api/agenda/public/me/bookings` | 🎫 | CL | O | Mis reservas (CL). |
| PATCH | `/api/agenda/public/me/profile` | 🎫 | CL | O | Completa nombre del cliente. |

---

## 2. Endpoints de tenant — sin scope de business — `/api/agenda/me/**`

| Método | Endpoint | Auth | PA | OW | TA | RC | SV | SO | CL | Restr. | Notas |
|--------|----------|------|----|----|----|----|----|----|----|--------|-------|
| GET | `/api/agenda/me/profile` | 🔑 |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | T | **Identidad RBAC del usuario:** `{userId, email, tenantId, roles[], platformAdmin, owner, tenantAdmin}`. Frontend lo consume al cargar para gatear UI. Side-effects: (1) bootstrap del OWNER si el tenant no lo tiene aún; (2) bootstrap de PLATFORM_ADMIN si el email del JWT matchea `platform.admin-email` (env `PLATFORM_ADMIN_EMAIL`). Ambos son idempotentes. |
| GET | `/api/agenda/me/tenant-admin` | 🔑 |  | ✓ | ✓ | ✓ | ✓ | ✓ |  | T | Resolver tenantId del usuario (legacy: usar `/me/profile`). Endpoint bootstrap; cualquier usuario con cuenta lo consume. |
| POST | `/api/agenda/me/tenant-admin/link` | 🔑 |  | ✓ | ✓ |  |  |  |  | — | Vincular Google email a TenantAccount existente (registrado por WhatsApp). Solo administradores. |
| POST | `/api/agenda/me/tenant-admin/identifiers` | 🔑 |  | ✓ | ✓ |  |  |  |  | — | Agregar segundo identificador (email/teléfono) a la cuenta. Solo administradores. |
| POST | `/api/agenda/me/tenant/invitations` | 🔑 |  | ✓ | ✓ | ⓑ |  |  |  | T | Crear miembro del tenant con rol RBAC. Quién puede invitar a qué (gate `canInviteRole`): TENANT_ADMIN → solo OWNER; RECEPTION → OW/TA (no se autoreplica); STAFF_OPERATOR/STAFF_VIEWER → OW/TA/RC (RC gestiona el equipo de sus sucursales). Crea `User` + role; para STAFF_* también crea `StaffMember`. **Side-effect:** envía mail al invitado (`StaffInvitationEmailService` → `AgendaMailer`): STAFF_*/RECEPTION reciben "te agregaron al equipo de {sucursales}"; TENANT_ADMIN recibe mail de bienvenida. Provider configurado por `mail.provider` (`log` default, `resend` en prod). El fallo del mailer es best-effort y no rompe la invitación. |
| PATCH | `/api/agenda/me/tenant/users/{userId}/roles` | 🔑 |  | ✓ |  |  |  |  |  | T | Reasignar por completo los roles de un usuario en este tenant. OWNER only. No puede tocar OWNER. |
| DELETE | `/api/agenda/me/tenant/users/{userId}` | 🔑 |  | ✓ |  |  |  |  |  | T | Revocar todo acceso al tenant: borra roles, desvincula `StaffMember`. OWNER only. |
| GET | `/api/agenda/me/public-link` | 🔑 |  | ✓ | ✓ |  |  |  |  | T | Link público del tenant (configuración). |
| GET | `/api/agenda/me/features` | 🔑 |  | ✓ | ✓ |  |  |  |  | T | Feature flags del tenant. |
| PUT | `/api/agenda/me/features` | 🔑 |  | ✓ |  |  |  |  |  | T | OWNER decide qué features están on; TA no. |

### Endpoints "me" mixtos: hoy autentican vía JWT pero operan sobre el `userId` del header `X-User-Id`

Estos endpoints son herencia del modelo previo. **Acción RBAC**: derivar `userId` del JWT y eliminar el header. Mientras tanto, su autorización es:

| Método | Endpoint | Auth | PA | OW | TA | RC | SV | SO | CL | Restr. | Notas |
|--------|----------|------|----|----|----|----|----|----|----|--------|-------|
| GET | `/api/agenda/me/businesses/{businessId}/bookings` | 🔑 |  |  |  |  |  |  | ✓ | T+O | "Mis reservas" del CL. Confirma: cliente autenticado lista sus reservas. |
| POST | `/api/agenda/me/businesses/{businessId}/bookings` | 🔑 |  |  |  |  |  |  | ✓ | T+O | Cliente crea su propia reserva (alternativa al flujo OTP público). |
| DELETE | `/api/agenda/me/businesses/{businessId}/bookings/{bookingId}` | 🔑 |  |  |  |  |  |  | ✓ | T+O | Cancela reserva propia dentro de ventana. |
| GET | `/api/agenda/me/subscriptions` | 🔑 |  |  |  |  |  |  | ✓ | T+O | Mis suscripciones (cliente). |
| POST | `/api/agenda/me/businesses/{businessId}/subscriptions` | 🔑 |  |  |  |  |  |  | ✓ | T+O | Compra de suscripción por cliente. |
| GET | `/api/agenda/me/subscriptions/{subscriptionId}/wallet` | 🔑 |  |  |  |  |  |  | ✓ | T+O | Wallet de la suscripción propia. |
| GET | `/api/agenda/me/notifications` | 🔑 |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | T+O | Notificaciones propias. Permitido a cualquier usuario sobre las suyas. |

---

## 3. Endpoints de administración por sucursal — `/api/agenda/me/businesses/{businessId}/**`

> **Regla general:** Todo endpoint en este grupo aplica **T+B**. La capa de autorización debe validar que (a) el business pertenece al tenant del usuario y (b) si el rol es RC/SV/SO, el `businessId` está entre sus sucursales asignadas.

### 3.1 Gestión de negocio (datos generales, settings, branding)

| Método | Endpoint | Auth | OW | TA | RC | SV | SO | Restr. | Notas |
|--------|----------|------|----|----|----|----|----|--------|-------|
| GET | `/api/agenda/me/businesses` | 🔑 | ✓ | ✓ | ✓ⓑ | ✓ⓑ | ✓ⓑ | T+B | RC/SV/SO ven solo las sucursales asignadas. |
| GET | `/api/agenda/me/businesses/{businessId}` | 🔑 | ✓ | ✓ | ✓ⓑ | ✓ⓑ | ✓ⓑ | T+B | Detalle. Idem. |
| POST | `/api/agenda/me/businesses` | 🔑 | ✓ | ✓ |  |  |  | T | Crear sucursal: TA permitido por spec ("Gestionar sucursales asociadas"). |
| PUT | `/api/agenda/me/businesses/{businessId}` | 🔑 | ✓ | ✓ |  |  |  | T+B | Actualizar sucursal. |
| PUT | `/api/agenda/me/businesses/{businessId}/categories` | 🔑 | ✓ | ✓ |  |  |  | T+B | Categorías asociadas. |
| GET | `/api/agenda/me/businesses/{businessId}/settings` | 🔑 | ✓ | ✓ | ✓ⓑ |  |  | T+B | RC necesita ver settings (ventana de cancelación) para gestionar reservas. |
| PUT | `/api/agenda/me/businesses/{businessId}/settings` | 🔑 | ✓ | ✓ |  |  |  | T+B | Solo OW/TA modifican. |
| POST | `/api/agenda/me/businesses/{businessId}/avatar` | 🔑 | ✓ | ✓ |  |  |  | T+B | Branding. |
| POST | `/api/agenda/me/businesses/{businessId}/banner` | 🔑 | ✓ | ✓ |  |  |  | T+B | Branding. |
| GET | `/api/agenda/me/businesses/{businessId}/photos` | 🔑 | ✓ | ✓ | ✓ⓑ | ✓ⓑ | ✓ⓑ | T+B | Lectura. |
| POST | `/api/agenda/me/businesses/{businessId}/photos` | 🔑 | ✓ | ✓ |  |  |  | T+B | Solo administradores publican. |
| POST | `/api/agenda/me/businesses/{businessId}/photos/upload` | 🔑 | ✓ | ✓ |  |  |  | T+B | Solo administradores. |
| DELETE | `/api/agenda/me/businesses/{businessId}/photos/{photoId}` | 🔑 | ✓ | ✓ |  |  |  | T+B | Solo administradores. |
| GET | `/api/agenda/me/businesses/{businessId}/hours` | 🔑 | ✓ | ✓ | ✓ⓑ | ✓ⓑ | ✓ⓑ | T+B | Necesario para todos los roles operativos. |
| PUT | `/api/agenda/me/businesses/{businessId}/hours` | 🔑 | ✓ | ✓ | ✓ⓑ |  |  | T+B | Horario semanal del negocio. Gate: `canManageBusinessOperations`. |

### 3.2 Servicios

| Método | Endpoint | Auth | OW | TA | RC | SV | SO | Restr. | Notas |
|--------|----------|------|----|----|----|----|----|--------|-------|
| GET | `/api/agenda/me/businesses/{businessId}/services` | 🔑 | ✓ | ✓ | ✓ⓑ | ✓ⓑ | ✓ⓑ | T+B | Todos los roles necesitan ver servicios. |
| POST | `/api/agenda/me/businesses/{businessId}/services` | 🔑 | ✓ | ✓ | ✓ⓑ |  |  | T+B | Alta de servicio. Gate: `canManageBusinessOperations`. |
| PUT | `/api/agenda/me/businesses/{businessId}/services/{serviceId}` | 🔑 | ✓ | ✓ | ✓ⓑ |  |  | T+B | Edita servicio. Gate: `canManageBusinessOperations`. |
| DELETE | `/api/agenda/me/businesses/{businessId}/services/{serviceId}` | 🔑 | ✓ | ✓ | ✓ⓑ |  |  | T+B | Soft-delete. Gate: `canManageBusinessOperations`. |

### 3.3 Equipo (Staff)

| Método | Endpoint | Auth | OW | TA | RC | SV | SO | Restr. | Notas |
|--------|----------|------|----|----|----|----|----|--------|-------|
| GET | `/api/agenda/me/businesses/{businessId}/staff` | 🔑 | ✓ | ✓ | ✓ⓑ | ✓ⓑ | ✓ⓑ | T+B | Listado del equipo. RC necesita para asignar reservas. SV/SO para ver compañeros. |
| POST | `/api/agenda/me/businesses/{businessId}/staff` | 🔑 | ✓ | ✓ | ✓ⓑ |  |  | T+B | Alta de profesional. RC gestiona el equipo de su sucursal. Gate: `canManageBusinessOperations`. |
| PUT | `/api/agenda/me/businesses/{businessId}/staff/{staffId}` | 🔑 | ✓ | ✓ | ✓ⓑ |  |  | T+B | Datos del miembro. Gate: `canManageBusinessOperations`. |
| PUT | `/api/agenda/me/businesses/{businessId}/staff/{staffId}/services` | 🔑 | ✓ | ✓ | ✓ⓑ |  |  | T+B | Asignación de servicios. Gate: `canManageBusinessOperations`. |
| DELETE | `/api/agenda/me/businesses/{businessId}/staff/{staffId}` | 🔑 | ✓ | ✓ | ✓ⓑ |  |  | T+B | Soft-delete. Gate: `canManageBusinessOperations`. |
| POST | `/api/agenda/me/businesses/{businessId}/staff/{staffId}/avatar` | 🔑 | ✓ | ✓ | ✓ⓑ |  |  | T+B | Foto. Gate: `canManageBusinessOperations`. Nota: futuro endpoint de "SO sube su propio avatar" puede caer en `/me/profile`. |
| PATCH | `/api/agenda/me/businesses/{businessId}/staff/{staffId}/schedule` | 🔑 | ✓ | ✓ | ✓ⓑ |  | ⓞ | T+B | Edita solo el `customSchedule` (horario semanal recurrente). OW/TA → cualquier staff. RC ⓑ → cualquier staff de su sucursal. SO → solo su propio `staffMember` (gate `canManageOwnStaffSchedule`). El backend clampa cada día dentro del horario del negocio. |

### 3.4 Clientes (CRM del tenant)

| Método | Endpoint | Auth | OW | TA | RC | SV | SO | Restr. | Notas |
|--------|----------|------|----|----|----|----|----|--------|-------|
| GET | `/api/agenda/me/businesses/{businessId}/clients` | 🔑 | ✓ | ✓ | ✓ⓑ |  | ✓ⓑ | T+B | RC y SO necesitan buscar clientes para crear reservas. SV no crea reservas → no necesita el CRM. |
| POST | `/api/agenda/me/businesses/{businessId}/clients` | 🔑 | ✓ | ✓ | ✓ⓑ |  | ✓ⓑ | T+B | Idem. |

### 3.5 Agenda de reservas

| Método | Endpoint | Auth | OW | TA | RC | SV | SO | Restr. | Notas |
|--------|----------|------|----|----|----|----|----|--------|-------|
| GET | `/api/agenda/me/businesses/{businessId}/agenda/bookings` | 🔑 | ✓ | ✓ | ✓ⓑ | ✓ⓑⓞ | ✓ⓑⓞ | T+B+O | OW/TA/RC ven todas; SV/SO solo las suyas (filtro automático server-side por `staffId = currentUser.staffId`). |
| POST | `/api/agenda/me/businesses/{businessId}/agenda/bookings` | 🔑 | ✓ | ✓ | ✓ⓑ |  | ✓ⓑⓞ | T+B+O | SO solo puede crear reservas para sí mismo. RC para cualquier staff de su sucursal. |
| PUT | `/api/agenda/me/businesses/{businessId}/agenda/bookings/{bookingId}/confirm` | 🔑 | ✓ | ✓ | ✓ⓑ |  | ✓ⓑⓞ | T+B+O | SO solo confirma reservas propias. |

> **Endpoints faltantes hoy** que la spec exige y deberán crearse en Fase 3/4:
> - `PUT /api/agenda/me/businesses/{businessId}/agenda/bookings/{bookingId}/reschedule` (RC, SO ⓞ)
> - `DELETE /api/agenda/me/businesses/{businessId}/agenda/bookings/{bookingId}` cancelar (RC, SO ⓞ)
> - `PUT /api/agenda/me/businesses/{businessId}/agenda/bookings/{bookingId}` modificar (RC, SO ⓞ)
> - `GET /api/agenda/me/staff/{staffId}/availability` y `PUT /api/agenda/me/staff/{staffId}/schedule` (SO ⓞ, gestiona su disponibilidad/horario)

### 3.6 Fidelización y comunicaciones

| Método | Endpoint | Auth | OW | TA | RC | SV | SO | Restr. | Notas |
|--------|----------|------|----|----|----|----|----|--------|-------|
| GET | `/api/agenda/me/businesses/{businessId}/loyalty/suggestions` | 🔑 | ✓ | ✓ |  |  |  | T+B | Sugerencias de fidelización (acción comercial). |
| PATCH | `/api/agenda/me/businesses/{businessId}/loyalty/suggestions/{suggestionId}` | 🔑 | ✓ | ✓ |  |  |  | T+B | |
| POST | `/api/agenda/me/businesses/{businessId}/loyalty/suggestions/{suggestionId}/send` | 🔑 | ✓ | ✓ |  |  |  | T+B | |
| GET | `/api/agenda/me/businesses/{businessId}/notification-templates` | 🔑 | ✓ | ✓ |  |  |  | T+B | Plantillas de mensajes salientes. |
| POST | `/api/agenda/me/businesses/{businessId}/notification-templates` | 🔑 | ✓ | ✓ |  |  |  | T+B | |
| PUT | `/api/agenda/me/businesses/{businessId}/notification-templates/{templateId}` | 🔑 | ✓ | ✓ |  |  |  | T+B | |
| DELETE | `/api/agenda/me/businesses/{businessId}/notification-templates/{templateId}` | 🔑 | ✓ | ✓ |  |  |  | T+B | |

### 3.7 Planes / suscripciones del negocio

| Método | Endpoint | Auth | OW | TA | RC | SV | SO | Restr. | Notas |
|--------|----------|------|----|----|----|----|----|--------|-------|
| GET | `/api/agenda/me/businesses/{businessId}/plans` | 🔑 | ✓ | ✓ | ✓ⓑ |  | ✓ⓑ | T+B | RC y SO ven planes (los referencian al crear reservas/subs). |
| GET | `/api/agenda/me/businesses/{businessId}/plans/{planId}` | 🔑 | ✓ | ✓ | ✓ⓑ |  | ✓ⓑ | T+B | |
| POST | `/api/agenda/me/businesses/{businessId}/plans` | 🔑 | ✓ | ✓ |  |  |  | T+B | Gestión comercial. |
| PUT | `/api/agenda/me/businesses/{businessId}/plans/{planId}` | 🔑 | ✓ | ✓ |  |  |  | T+B | |
| DELETE | `/api/agenda/me/businesses/{businessId}/plans/{planId}` | 🔑 | ✓ | ✓ |  |  |  | T+B | |

### 3.8 Integración con bots

| Método | Endpoint | Auth | OW | TA | RC | SV | SO | Restr. | Notas |
|--------|----------|------|----|----|----|----|----|--------|-------|
| PUT | `/api/agenda/me/bots/{botId}/linked-businesses` | 🔑 | ✓ |  |  |  |  |  | T | Vincular bot a sucursales. Solo OWNER por spec ("Configurar bot"). |

---

## 4. Endpoints de plataforma — `/api/agenda/platform/**`

> **Estado actual: CRÍTICO.** Hoy abiertos sin autenticación. Fase 3 los protege.

| Método | Endpoint | Auth | PA | Notas |
|--------|----------|------|----|-------|
| GET | `/api/agenda/platform/categories` | 🔑 | ✓ | Catálogo global. |
| POST | `/api/agenda/platform/categories` | 🔑 | ✓ | Crea categoría. |
| PUT | `/api/agenda/platform/categories/{id}` | 🔑 | ✓ | Edita. |
| DELETE | `/api/agenda/platform/categories/{id}` | 🔑 | ✓ | Elimina. |
| PUT | `/api/agenda/platform/categories/{id}/synonyms` | 🔑 | ✓ | Fusiona sinónimos. |

---

## 5. Endpoints legacy del chatbot (fuera de scope inmediato pero documentados)

> Los siguientes endpoints están actualmente **sin autenticación**. No forman parte del MVP de RBAC de Agenda. Se documentan aquí para no perderlos de vista; **deberán bloquearse o reclasificarse en una iteración posterior** (al menos restringir todo el prefijo `/api/v1/webhook/**` a webhooks con secret válido, y `/api/tenants/{tenantId}/**` + `/api/bots/**` a `PLATFORM_ADMIN`).

### 5.1 Webhooks (no requieren rol, validación por verify-token)

| Método | Endpoint | Auth | Notas |
|--------|----------|------|-------|
| GET | `/api/v1/webhook/whatsapp` | 🔧 | Meta verify challenge. |
| POST | `/api/v1/webhook/whatsapp` | 🔧 | Mensajes entrantes / status updates. Validar firma `X-Hub-Signature-256`. |
| POST | `/api/v1/webhook/telegram` | 🔧 | Bot Telegram. Validar secret token. |
| POST | `/api/v1/webhook/message` | 🔧 | Canal web. |

### 5.2 Administración global de chatbot (deberán ser PA)

| Método | Endpoint | Rol objetivo | Notas |
|--------|----------|--------------|-------|
| POST | `/api/auth/google` | ❌ → mantener público | Endpoint de login, no debe pedir auth. |
| POST | `/api/chat/no-rag` | PA | Diagnóstico. |
| GET, POST, PUT, DELETE | `/api/bots`, `/api/bots/{botId}**` | PA | Gestión global de bots. |
| GET, POST | `/api/faqs**` | PA | FAQs globales. |
| GET, POST, PUT, DELETE | `/api/tenants/{tenantId}/menus**` | PA, OW (T) | Menús del bot por tenant. OWNER nutre la información del bot. |
| GET, POST, DELETE | `/api/tenants/{tenantId}/triggers**` | PA, OW (T) | Triggers del bot. |
| GET, POST, PATCH | `/api/tenants/{tenantId}/appointments**` | PA, OW (T) | Citas legacy (pre-Agenda). |
| GET, POST, PUT, DELETE | `/api/tenants/{tenantId}/knowledge**` | PA, OW (T) | RAG knowledge del bot. OWNER lo nutre. |
| GET, POST, PUT | `/api/tenants/{tenantId}/lessons**` | PA, OW (T) | Lecciones del bot. |
| GET, PUT | `/api/tenants/{tenantId}/features**` | PA | Feature flags del tenant (interno). |
| POST | `/api/tenants/{tenantId}/conversations/{conversationId}/feedback` | (público con conversationId válido) | El cliente final reporta. Validar pertenencia de conversación al tenant. |
| GET | `/api/tenants/{tenantId}/feedback` | PA, OW (T) | Listado para análisis interno. |
| POST | `/api/tenants/{tenantId}/feedback/{feedbackId}/promote-to-faq` | PA, OW (T) | Curación de FAQs. |

---

## 6. Matriz resumen por capacidad (referencia rápida)

Mapeo directo desde la matriz de permisos de la spec a los grupos de endpoints arriba:

| Capacidad | OW | TA | RC | SV | SO | Endpoints clave |
|-----------|----|----|----|----|----|-----------------|
| Gestionar sucursales | ✓ | ✓ |  |  |  | §3.1 |
| Gestionar servicios | ✓ | ✓ |  |  |  | §3.2 |
| Gestionar staff | ✓ | ✓ |  |  |  | §3.3 |
| Gestionar admins | ✓ |  |  |  |  | Pendiente: endpoints de invitación/rol (Fase 1). |
| Configurar branding | ✓ | ✓ |  |  |  | §3.1 (avatar, banner, photos) |
| Configurar bot | ✓ |  |  |  |  | §3.8 |
| Eliminar workspace | ✓ |  |  |  |  | Pendiente: `DELETE /api/agenda/me/tenant`. |
| Transferir workspace | ✓ |  |  |  |  | Pendiente: `POST /api/agenda/me/tenant/transfer`. |
| Ver agenda completa | ✓ | ✓ | ✓ⓑ |  |  | §3.5 GET (RC limitado a sucursales) |
| Gestionar agenda completa | ✓ | ✓ | ✓ⓑ |  |  | §3.5 mutaciones |
| Ver agenda propia | ✓ | ✓ | ✓ⓑ | ✓ⓑⓞ | ✓ⓑⓞ | §3.5 GET (filtro server-side para SV/SO) |
| Gestionar agenda propia | ✓ | ✓ |  |  | ✓ⓑⓞ | §3.5 mutaciones |
| Gestionar disponibilidad/horarios propios | ✓ | ✓ |  |  | ✓ⓑⓞ | Pendiente: endpoints de schedule por staff |
| Consultar disponibilidad pública | — | — | — | — | — | §1, role CL/PUB |
| Crear reserva como cliente | — | — | — | — | — | §1 + §2 (CL) |
| Consultar/cancelar reserva propia (cliente) | — | — | — | — | — | §1 + §2 (CL ⓞ) |

---

## 7. Notas para la implementación (Fase 2 y 3)

1. **Resolución de roles efectivos.**
   - PA: presencia del `userId` en tabla `agenda_platform_admins`.
   - OW/TA/RC/SV/SO: filas en `agenda_user_roles` filtradas por `tenant_id = currentTenant`. `business_id` define scope (NULL = tenant-wide para OW/TA).
   - CL: implícito si el usuario no tiene roles administrativos en el tenant del recurso.

2. **`@PreAuthorize` propuesto.** Definir SpEL helpers en un bean reutilizable:
   - `@PreAuthorize("@authz.canManageBusiness(#businessId)")` → OW/TA con tenant ownership.
   - `@PreAuthorize("@authz.canOperateAgenda(#businessId)")` → OW/TA, o RC asignado.
   - `@PreAuthorize("@authz.canEditOwnAgenda(#businessId, #staffId)")` → SO sobre su propio staffId.
   - `@PreAuthorize("@authz.isPlatformAdmin()")` → PA.

3. **Filtro server-side para SV/SO.** Los endpoints GET de agenda deben pasar por un decorador de query que, si el rol efectivo es SV o SO, inyecte `staffId = currentUser.staffId` en el filtro. Nunca devolver bookings ajenas aunque la app no las pida.

4. **Header `X-User-Id` queda deprecado.** El `userId` se deriva del JWT (`sub` o lookup por email). Migrar `MeBookingsController`, `MeSubscriptionsController` y `MeNotificationsController` en Fase 3. Mientras no se elimine el header, ignorarlo y usar el del JWT.

5. **CLIENT vía OTP no es CLIENT vía JWT.** Las dos vías de identificación deben converger a un mismo `userId`. Cuando un OTP autentica a un cliente cuyo email/teléfono ya tiene cuenta Google asociada, devolver al frontend que puede "elevar" la sesión a JWT.

6. **Respuestas uniformes de error** (Fase 3):
   - 401 `auth.unauthenticated` — sin token o token inválido.
   - 403 `auth.forbidden` — rol no autorizado para la acción.
   - 403 `auth.out_of_scope` — rol autorizado pero el `businessId` está fuera del scope asignado (RC/SV/SO).
   - 403 `auth.ownership_violation` — operación sobre recurso ajeno (SV/SO/CL sobre booking que no es suyo).

7. **Auditoría.** Las acciones marcadas con OW exclusivo (cambio de propiedad, eliminación de workspace, modificación de admins, configuración de bot, eliminación de servicios) deben quedar registradas en `agenda_audit_log(actor_user_id, tenant_id, action, resource_id, payload, at)`.

---

## 8. Endpoints que faltan en el backend y son obligatorios para la spec

Para alcanzar 100% de la matriz de la spec, se deberán crear estos endpoints (anotados aquí para que Fase 2/3 no los pierda de vista):

| Endpoint | Roles | Notas |
|----------|-------|-------|
| `PUT /api/agenda/me/businesses/{businessId}/agenda/bookings/{bookingId}` | OW, TA, RC ⓑ, SO ⓑⓞ | Modificar reserva. |
| `PUT /api/agenda/me/businesses/{businessId}/agenda/bookings/{bookingId}/reschedule` | OW, TA, RC ⓑ, SO ⓑⓞ | Reprogramar. Dispara validación de no-solapamiento global (Fase 4). |
| `DELETE /api/agenda/me/businesses/{businessId}/agenda/bookings/{bookingId}` | OW, TA, RC ⓑ, SO ⓑⓞ | Cancelar reserva interna. |
| `GET /api/agenda/me/staff/me/agenda` | SV ⓞ, SO ⓞ | Mi agenda consolidada (multi-sucursal). |
| `PUT /api/agenda/me/staff/me/schedule` | SO ⓞ | Horarios propios por sucursal. |
| `GET /api/agenda/me/staff/me/availability` | SO ⓞ, SV ⓞ | Disponibilidad propia. |
| `PUT /api/agenda/me/staff/me/availability` | SO ⓞ | Editar disponibilidad propia. |
| ~~`POST /api/agenda/me/tenant/invitations`~~ | OW (admins), OW+TA (recepción/staff) | ✅ Entregado en Fase 3.5. |
| ~~`PATCH /api/agenda/me/tenant/users/{userId}/roles`~~ | OW | ✅ Entregado en Fase 3.5. |
| ~~`DELETE /api/agenda/me/tenant/users/{userId}`~~ | OW | ✅ Entregado en Fase 3.5 (desvincula StaffMember sin borrarlo). |
| `POST /api/agenda/me/tenant/transfer` | OW | Transferir propiedad. |
| `DELETE /api/agenda/me/tenant` | OW | Cerrar workspace. |
