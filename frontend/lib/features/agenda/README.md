# Módulo AGENDA — Frontend (Flutter)

Frontend del módulo AGENDA dentro del mismo `pubspec.yaml` del bot. Vive en paralelo a las features del chatbot **sin tocar** ningún archivo del bot (ver [PLAN_AGENDA_FRONTEND.md](../../../../PLAN_AGENDA_FRONTEND.md)).

---

## Sprints entregados (estado actual)

- **FE-1 (público + plataforma)**:
  - Buscador público (`/agenda/public/search`) y ficha pública (`/agenda/public/business/:id`).
  - Catálogo global de categorías (`/agenda/platform/categories`).
- **FE-2 (admin de negocio)**:
  - Panel bajo `/home` (sin `tenantId` en URL).
  - CRUD de negocio/horarios/servicios/planes/plantillas/loyalty/staff.
  - Feature flags AGENDA via `GET/PUT /api/agenda/me/features`.
- **FE-3 (usuario final)**:
  - Mis suscripciones / wallet / bookings / notificaciones bajo `/agenda/me/**`.

### Link público para clientes

Cada negocio expone un link público para que los clientes reserven (web con hash routing).
Este link se obtiene desde el panel privado (empresa) vía `GET /api/agenda/me/public-link`
y se muestra/copia desde el item **“Link público”** del sidebar del panel.

- `/#/agenda/<slug>` (URL amigable, recomendada)
- `/#/agenda/public/business/{businessId}` (ruta directa, interna)

### Nota de UX (decisión)

- “Citas/Agenda” **no** se configura desde el panel del bot. Se gestiona desde el panel del negocio (AGENDA) y se comparte vía link público.

---

## Dos vistas: privada (empresa) vs pública (clientes)

AGENDA tiene **dos experiencias** bien distintas:

### 1) Vista privada (empresa / admin)

- **Objetivo**: operar el negocio con info privada (configuración, staff, servicios, planes, horarios, etc.).
- **Requiere login** (Google) y tener tenant Agenda asociado al email.
- **Entrada**: `/home` (resuelve el tenant por email y muestra el dashboard).
- **Rutas principales**:
  - `/#/home` → dashboard privado (Tenant)
  - `/#/home/businesses/:businessId` → panel del negocio con tabs (Horarios, Servicios, Planes, Settings, Loyalty, Equipo, etc.)
- **Sidebar**:
  - **“Inicio/Home”**: resumen del negocio y accesos rápidos.
  - **“Agenda”**: abre el **calendario privado** (turnos) dentro del panel (ruta `/home?section=agenda`).
  - El vínculo público **no** vive en el sidebar: está dentro del calendario como botón **“Copiar vínculo”**.

### 2) Vista pública (clientes)

- **Objetivo**: que un cliente pueda ver disponibilidad y **registrarse** en turnos/horarios disponibles.
- **No requiere login**.
- **Entradas**:
  - `/#/agenda/search` → buscador público (explorar negocios)
  - `/#/agenda/<slug>` → link amigable directo al negocio (flujo recomendado para compartir)
  - `/#/agenda/public/business/:id` → ficha pública directa del negocio

> Nota: hoy el panel privado ya genera y expone la URL amigable; el flujo de “reservar turno” del cliente vive bajo las rutas públicas.

---

## Importante: “Home” NO es “Agenda”

Para evitar confusiones en UX y en el código:

- **Home** (panel privado) = **dashboard/resumen** del negocio.
  - Es el “inicio” del admin: métricas, accesos a configuración, listado de negocios, etc.
  - Ruta: `/#/home` y `/#/home/**`.

- **Agenda** = **turnos/calendario** (la grilla diaria/semanal, turnos tomados, gestión de reservas).
  - Es una pantalla distinta al dashboard.
  - **Estado actual**: el sidebar del panel privado abre una sección **Agenda (calendario)** (`/home?section=agenda`) con selector de fecha y lista de turnos del día. A futuro se reemplazará por un calendario full (día/semana) con endpoints admin dedicados.

- **Público (clientes)** = búsqueda + ficha + registro en disponibilidad.
  - Rutas: `/#/agenda/search`, `/#/agenda/<slug>`, `/#/agenda/public/business/:id`.

## Estructura de carpetas

```
lib/
├── core/                                # theme + config (intocados)
├── models/agenda/                       # NUEVO — espejos de DTOs del backend
│   ├── agenda_json.dart                 # helpers de parseo defensivo
│   ├── category.dart
│   ├── business_summary.dart
│   ├── business.dart
│   └── agenda_service.dart
├── services/
│   ├── api_service.dart                 # bot — INTOCADO
│   ├── agenda_api_service.dart          # NUEVO — solo /api/agenda/**
│   └── agenda_api_exception.dart        # NUEVO — error tipado
├── providers/
│   ├── auth_provider.dart               # bot — reusado solo-lectura
│   ├── bot_provider.dart                # bot — INTOCADO
│   └── agenda/                          # NUEVO
│       ├── agenda_api_provider.dart
│       ├── public/{search, categories, business_detail}_provider.dart
│       └── platform/categories_admin_provider.dart
├── widgets/
│   ├── business_hours_card.dart         # bot — INTOCADO
│   └── agenda/                          # NUEVO
│       ├── category_chip.dart
│       ├── business_summary_card.dart
│       └── agenda_state_views.dart
└── features/agenda/                     # NUEVO
    ├── agenda_landing_screen.dart       # /agenda
    ├── theme/agenda_tokens.dart         # tiers, breakpoints, radios
    ├── public/
    │   ├── search_screen.dart
    │   ├── category_businesses_screen.dart
    │   └── public_business_detail_screen.dart
    └── platform/
        ├── categories_admin_screen.dart
        └── widgets/category_form_dialog.dart
```

---

## Cómo arrancar

### 1. Backend
```bash
cd backend
docker-compose up -d postgres   # desde la raíz del repo
mvn spring-boot:run             # arranca en localhost:8080
```

### 2. Frontend (Web)
```bash
cd frontend
cp .env.example .env            # editar si hace falta
flutter pub get
./run-web.ps1                   # PowerShell — arranca en localhost:5000
# o: flutter run -d chrome --web-port=5000
```

Acceder a `http://localhost:5000/#/agenda` (landing del módulo). Sin login podés entrar al buscador público.

### 3. Variables de entorno relevantes (`.env`)

```env
# Existente (bot)
API_BASE_URL=http://localhost:8080/api

# AGENDA module
AGENDA_API_BASE_URL=                # vacío → ${API_BASE_URL}/agenda
AGENDA_PLATFORM_ADMIN=true          # mostrar tile "Plataforma" en /agenda
AGENDA_DEFAULT_TENANT_ID=tenant-abc # dev only — pre-rellena el form de búsqueda
AGENDA_DEFAULT_USER_ID=             # dev only — X-User-Id mientras no hay auth real
```

---

## Cómo correr los tests

```bash
cd frontend

# Solo tests del módulo AGENDA
flutter test test/agenda/

# Todo el suite (incluye los del bot)
flutter test

# Análisis estático
flutter analyze
```

Los tests usan `FakeAgendaApiService` (`test/agenda/fake_agenda_api.dart`) que se inyecta vía `ProviderScope` overrides — no tocan red.

---

## Reglas innegociables

1. **No importar** desde `lib/features/agenda/**` ni `lib/providers/agenda/**` ningún archivo bajo:
   - `lib/features/{bot_*, dashboard, menus, knowledge, services, appointments, auth}`
   - `lib/services/api_service.dart`
   - `lib/providers/bot_provider.dart`
   - `lib/models/{bot, menu, knowledge, service, appointment}.dart`
2. Reusar siempre `lib/core/theme.dart` (paleta) — nunca redefinir tokens del bot.
3. Tokens visuales propios del módulo van en `features/agenda/theme/agenda_tokens.dart`.
4. Toda llamada HTTP pasa por `AgendaApiService` (inyectado vía `agendaApiServiceProvider`).
5. Las excepciones del backend se mapean a `AgendaApiException` y los providers traducen el `code` a UX legible.

---

## Endpoints consumidos (Sprint FE-1)

| Método | Endpoint | Provider |
|---|---|---|
| GET | `/api/agenda/public/search?q=&tenantId=` | `searchProvider` |
| GET | `/api/agenda/public/categories` | `publicCategoriesProvider` |
| GET | `/api/agenda/public/categories/{slug}/businesses` | `businessesByCategoryProvider` |
| GET | `/api/agenda/public/businesses/{id}` | `publicBusinessProvider` |
| GET | `/api/agenda/public/businesses/{id}/services` | `publicBusinessServicesProvider` |
| GET | `/api/agenda/platform/categories` | `categoriesAdminProvider.load` |
| POST | `/api/agenda/platform/categories` | `categoriesAdminProvider.create` |
| PUT | `/api/agenda/platform/categories/{id}` | `categoriesAdminProvider.update` |
| DELETE | `/api/agenda/platform/categories/{id}` | `categoriesAdminProvider.delete` |

---

## Pendiente (próximos sprints)

- Mejoras: consolidar navegación “Agenda” del sidebar para abrir panel interno + compartir link público.

Detalle en [PLAN_AGENDA_FRONTEND.md §8](../../../../PLAN_AGENDA_FRONTEND.md).
