# Política de datos — Agenda pública (OTP / sesión cliente)

Documento operativo para cumplimiento (retención, borrado, subprocesadores) del flujo **web pública** de reservas (`/reservar`, OTP WhatsApp, sesión `X-Agenda-Client-Session`).

No aplica al panel tenant autenticado (JWT) ni al bot WhatsApp «mis citas» (identidad = número del chat).

---

## 1. Datos que tratamos

| Dato | Dónde | Propósito | Base |
|------|--------|-----------|------|
| Teléfono (normalizado) | `agenda_users`, OTP/sesión | Identificar cliente, reservar, «mis reservas» | Ejecución del servicio |
| Nombre / email | `agenda_users` | Ficha de cliente y confirmaciones | Ejecución del servicio |
| Hash OTP / hash sesión / hash teléfono (audit) | `agenda_otp_challenges`, `agenda_client_sessions`, `agenda_security_audit` | Seguridad, anti-abuso, multi-instancia | Interés legítimo (seguridad) |
| IP cliente (truncada en logs debug) | `agenda_security_audit` | Rate limit distribuido, auditoría | Interés legítimo (seguridad) |
| Reservas | `agenda_bookings` | Servicio de turnos | Ejecución del servicio |

**No almacenamos** el código OTP en claro: solo hash con pepper (`AGENDA_PHONE_VERIFICATION_HASH_PEPPER`).

---

## 2. Retención

| Artefacto | TTL / retención | Mecanismo |
|-----------|-----------------|-----------|
| Desafío OTP | `agenda.phone.verification.ttl-minutes` (default 10 min) | Expira en uso; cleanup periódico |
| Sesión cliente pública | `session-minutes` (default **15 min**) | Expira; filas antiguas eliminadas por scheduler |
| Audit seguridad OTP/sesión/HTTP | `audit-retention-days` (default **90 días**) | `AgendaPhoneVerificationCleanupScheduler` |
| Perfil cliente (`agenda_users`) | Mientras exista relación comercial con el tenant | Soft delete no aplica a users; ver borrado |
| Reservas | Política del negocio / obligaciones contables del tenant | Fuera del scope de este doc |

Configuración: `backend/src/main/resources/application.yml` → `agenda.phone.verification.*`.

---

## 3. Borrado y derechos del titular

### Automático
- OTP vencidos, sesiones expiradas y audit > retención: job `AgendaPhoneVerificationCleanupScheduler` (`cleanup-cron`).

### A pedido (tenant / plataforma)
- **Rectificación:** el cliente puede actualizar nombre vía `PATCH /api/agenda/public/me/profile` (con sesión OTP vigente).
- **Acceso:** reservas propias vía `GET /api/agenda/public/me/bookings` (sesión OTP).
- **Supresión:** no hay autoservicio público de borrado total; el tenant admin o soporte plataforma debe:
  1. Anular/cerrar reservas según política del negocio.
  2. Anonimizar o eliminar fila en `agenda_users` si no hay obligación legal de conservar.
  3. Las filas de audit **no contienen PII en claro** (hashes); expiran solas a los 90 días.

### Incidentes
- Rotar `AGENDA_PHONE_VERIFICATION_HASH_PEPPER` invalida OTP/sesiones/audit hashes previos (planificar ventana de mantenimiento).

---

## 4. Subprocesadores

| Proveedor | Uso | Datos expuestos | Ubicación / notas |
|-----------|-----|-----------------|-------------------|
| **PostgreSQL** (Neon, RDS, etc.) | Persistencia agenda | Hashes, teléfonos, reservas | Según contrato cloud del operador |
| **WhatsApp / Meta** (vía adaptador bot) | Entrega OTP | Teléfono + código en tránsito | Política Meta; solo envío, no almacenamiento Meta en nuestro backend |
| **Hosting backend** (Render, VM, etc.) | API HTTPS | Tráfico HTTP | TLS obligatorio en prod (`PUBLIC_BACKEND_URL` / `PUBLIC_FRONTEND_URL` con `https://`) |
| **Hosting frontend** (Vercel, etc.) | UI `/reservar` | Sesión en `SharedPreferences` local del navegador | Token de sesión 15 min; no cookies de auth de plataforma |

Actualizar esta tabla cuando se incorpore un proveedor nuevo (email, SMS, analytics).

---

## 5. Seguridad técnica (resumen)

- Reserva pública **solo** con sesión OTP (`X-Agenda-Client-Session`); sin bypass `clientId` ni API pública de alta de clientes.
- Rate limit OTP y HTTP por IP vía **PostgreSQL** (`agenda_security_audit`) — coherente multi-instancia.
- Prod: pepper distinto de dev + URLs públicas HTTPS (`AgendaPhoneVerificationStartupValidator`).
- Landing y buscador (`/api/agenda/public/search`, categorías, ficha negocio) permanecen públicos **sin** datos personales del visitante.

---

## 6. Responsables

- **Responsable del tratamiento (tenant):** cada negocio que usa Agenda.
- **Encargado del tratamiento (plataforma):** operador de BotAI/Konecta según contrato con el tenant.

Revisión sugerida: anual o ante cambio de subprocesador / flujo OTP.
