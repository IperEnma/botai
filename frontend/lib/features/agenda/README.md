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

Cada negocio expone un link público para que los clientes reserven (web con hash routing):

- `/#/agenda/public/business/{businessId}`

### Nota de UX (decisión)

- “Citas/Agenda” **no** se configura desde el panel del bot. Se gestiona desde el panel del negocio (AGENDA) y se comparte vía link público.

---

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
