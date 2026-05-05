# Frontend BotAI Admin — Documentación técnica

> Referencia operativa del frontend Flutter. Para el plan de sprints y decisiones de diseño ver [PLAN_AGENDA_FRONTEND.md](../../PLAN_AGENDA_FRONTEND.md).

---

## Tabla de contenidos

1. [Requisitos previos](#1-requisitos-previos)
2. [Configuración inicial](#2-configuración-inicial)
3. [Variables de entorno (.env)](#3-variables-de-entorno-env)
4. [Levantar la aplicación](#4-levantar-la-aplicación)
5. [Compilar y construir](#5-compilar-y-construir)
6. [Correr los tests](#6-correr-los-tests)
7. [Rutas de navegación (GoRouter)](#7-rutas-de-navegación-gorouter)
8. [Llamadas a la API — referencia completa](#8-llamadas-a-la-api--referencia-completa)
   - [Bot (ApiService — módulo existente)](#81-bot-apiservice--módulo-existente)
   - [Agenda — Públicos sin auth](#82-agenda--públicos-sin-auth)
   - [Agenda — Platform admin](#83-agenda--platform-admin)
   - [Agenda — Tenant features](#84-agenda--tenant-features)
   - [Agenda — Tenant businesses](#85-agenda--tenant-businesses)
   - [Agenda — Tenant services](#86-agenda--tenant-services)
   - [Agenda — Tenant plans](#87-agenda--tenant-plans)
   - [Agenda — Tenant loyalty](#88-agenda--tenant-loyalty)
   - [Agenda — Tenant notification templates](#89-agenda--tenant-notification-templates)
   - [Agenda — Me subscriptions](#810-agenda--me-subscriptions)
   - [Agenda — Me bookings](#811-agenda--me-bookings)
   - [Agenda — Me notifications](#812-agenda--me-notifications)
9. [Estructura de paquetes](#9-estructura-de-paquetes)
10. [State management — Riverpod providers](#10-state-management--riverpod-providers)
11. [Arquitectura y capas](#11-arquitectura-y-capas)
12. [Dependencias principales](#12-dependencias-principales)

---

## 1. Requisitos previos

| Herramienta | Versión mínima | Para qué |
|---|---|---|
| Flutter SDK | 3.11.0 | Compilar la app |
| Dart | incluido en Flutter | Lenguaje |
| Android Studio / VS Code | cualquier reciente | IDE + emulador Android |
| Chrome | cualquier reciente | Target web (`flutter run -d chrome`) |
| Xcode (solo Mac) | 15+ | Target iOS/macOS |

Verificar instalación:

```bash
flutter --version      # debe decir 3.11.x o mayor
flutter doctor         # no debe haber errores críticos
```

---

## 2. Configuración inicial

```bash
# 1. Entrar al directorio frontend
cd frontend

# 2. Copiar el archivo de entorno
cp .env.example .env

# 3. Editar .env con los valores reales (ver sección 3)
# (mínimo: API_BASE_URL y GOOGLE_CLIENT_ID_WEB)

# 4. Instalar dependencias
flutter pub get
```

---

## 3. Variables de entorno (.env)

El archivo `.env` se ubica en `frontend/.env` y se carga al inicio con `flutter_dotenv`.
**Nunca commitear `.env` con valores reales.**

| Variable | Obligatorio | Default | Descripción |
|---|---|---|---|
| `API_BASE_URL` | Sí | `http://localhost:8080/api` | Base URL del backend (bot + agenda) |
| `GOOGLE_CLIENT_ID_WEB` | Sí (prod) | — | Client ID de OAuth para web |
| `GOOGLE_CLIENT_ID_ANDROID` | Sí (Android) | — | Client ID de OAuth para Android |
| `GOOGLE_CLIENT_ID_IOS` | Sí (iOS) | — | Client ID de OAuth para iOS |
| `AGENDA_API_BASE_URL` | No | `${API_BASE_URL}/agenda` | Override para la base URL de AGENDA |
| `AGENDA_PLATFORM_ADMIN` | No | `false` | Si `true`, muestra tile "Plataforma" en el landing |
| `AGENDA_DEFAULT_TENANT_ID` | No (solo dev) | — | Tenant precargado para entrar sin login real |
| `AGENDA_DEFAULT_USER_ID` | No (solo dev) | — | UserId enviado como `X-User-Id` sin auth real |

Ejemplo de `.env` para desarrollo local:

```dotenv
API_BASE_URL=http://localhost:8080/api
GOOGLE_CLIENT_ID_WEB=123456789-abc.apps.googleusercontent.com
AGENDA_PLATFORM_ADMIN=true
AGENDA_DEFAULT_TENANT_ID=550e8400-e29b-41d4-a716-446655440000
AGENDA_DEFAULT_USER_ID=usr-dev-001
```

---

## 4. Levantar la aplicación

### Web (desarrollo — más rápido)

```bash
cd frontend
flutter run -d chrome
```

O usando el script PowerShell incluido:

```powershell
cd frontend
.\run-web.ps1
```

### Android (emulador)

```bash
# Listar dispositivos disponibles
flutter devices

# Correr en el primer emulador Android
flutter run -d emulator-5554
```

### Android (dispositivo físico)

```bash
# Activar depuración USB en el teléfono, luego:
flutter run -d <device-id>
```

### Hot reload y hot restart

| Tecla | Acción |
|---|---|
| `r` | Hot reload (recarga widgets sin perder estado) |
| `R` | Hot restart (reinicia la app completa) |
| `q` | Salir |

---

## 5. Compilar y construir

### Web — producción

```bash
cd frontend
flutter build web --release
# Output: frontend/build/web/
```

### Android APK

```bash
flutter build apk --release
# Output: frontend/build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

### iOS (solo Mac)

```bash
flutter build ios --release
```

### Análisis estático

```bash
flutter analyze
```

---

## 6. Correr los tests

```bash
cd frontend

# Todos los tests
flutter test

# Solo tests de AGENDA
flutter test test/agenda/

# Con coverage
flutter test --coverage
# Reporte en: coverage/lcov.info
```

---

## 7. Rutas de navegación (GoRouter)

La navegación se gestiona con `go_router` desde `lib/core/router.dart`.
La ruta inicial es `/agenda`.

### Reglas de redirección

- `/agenda` y `/agenda/public/**` → **accesibles sin login** (buscador público).
- Cualquier otra ruta → redirige a `/login` si no hay sesión.
- Si hay sesión y se intenta `/login` → redirige a `/dashboard`.

### Tabla de rutas

| Ruta | Screen | Auth requerida | Descripción |
|---|---|---|---|
| `/login` | `LoginScreen` | No | Pantalla de login Google |
| `/dashboard` | `DashboardScreen` | Sí | Panel de bots del usuario |
| `/bot/:botId` | `BotDetailScreen` | Sí | Detalle y configuración de un bot |
| `/agenda` | `AgendaLandingScreen` | No | Landing del módulo AGENDA |
| `/agenda/public/search` | `SearchScreen` | No | Buscador público de negocios |
| `/agenda/public/categories/:slug` | `CategoryBusinessesScreen` | No | Negocios filtrados por categoría (`?tenantId=`) |
| `/agenda/public/business/:id` | `PublicBusinessDetailScreen` | No | Detalle público de un negocio |
| `/agenda/platform/categories` | `CategoriesAdminScreen` | Sí (PLATFORM_ADMIN) | Gestión del catálogo global |
| `/agenda/tenants/:tenantId` | `TenantHomeScreen` | Sí | Dashboard del tenant admin |
| `/agenda/tenants/:tenantId/businesses/:businessId` | `BusinessDetailScreen` | Sí | Detalle de negocio del tenant |
| `/agenda/me/subscriptions` | `MySubscriptionsScreen` | Sí | Suscripciones del usuario |
| `/agenda/me/subscriptions/:id/wallet` | `WalletScreen` | Sí | Wallet / créditos de una suscripción |
| `/agenda/me/bookings` | `MyBookingsScreen` | Sí | Reservas del usuario |
| `/agenda/me/bookings/new` | `CreateBookingScreen` | Sí | Crear reserva (`?tenantId=&businessId=`) |
| `/agenda/me/notifications` | `MyNotificationsScreen` | Sí | Notificaciones del usuario |

### Navegar con GoRouter

```dart
// Push simple
context.go('/agenda');

// Con path param
context.go('/agenda/tenants/$tenantId');

// Con query params
context.go('/agenda/me/bookings/new?tenantId=$tid&businessId=$bid');
```

---

## 8. Llamadas a la API — referencia completa

Hay dos clientes HTTP independientes:

| Cliente | Archivo | Base URL | Módulo |
|---|---|---|---|
| `ApiService` | `lib/services/api_service.dart` | `API_BASE_URL` | Bot (existente) |
| `AgendaApiService` | `lib/services/agenda_api_service.dart` | `AGENDA_API_BASE_URL` | AGENDA |

`AgendaApiService` agrega automáticamente:
- `Authorization: Bearer <token>` si hay sesión.
- `X-User-Id: <userId>` en endpoints que lo requieren (`sendUserId: true`).
- `Idempotency-Key` en `createBooking` si se provee.
- Timeout de 15 s por defecto.
- Lanza `AgendaApiException` con `message`, `status` y `code` en errores no-2xx.

---

### 8.1 Bot (ApiService — módulo existente)

Base: `API_BASE_URL` (ej. `http://localhost:8080/api`)

| Método | Endpoint | Descripción |
|---|---|---|
| `POST` | `/auth/google` | Login con Google ID token |
| `GET` | `/bots` | Listar bots del usuario |
| `POST` | `/bots` | Crear bot |
| `PUT` | `/bots/:id` | Actualizar bot |
| `DELETE` | `/bots/:id` | Eliminar bot |
| `GET` | `/tenants/:id/menus` | Listar menús |
| `POST` | `/tenants/:id/menus` | Crear menú |
| `PUT` | `/tenants/:id/menus/:menuId` | Actualizar menú |
| `DELETE` | `/tenants/:id/menus/:menuId` | Eliminar menú |
| `GET` | `/tenants/:id/business-hours` | Horario del negocio |
| `PUT` | `/tenants/:id/business-hours` | Guardar horario |
| `GET` | `/tenants/:id/services` | Listar servicios del bot |
| `POST` | `/tenants/:id/services` | Crear servicio del bot |
| `PUT` | `/tenants/:id/services/:sId` | Actualizar servicio |
| `DELETE` | `/tenants/:id/services/:sId` | Eliminar servicio |
| `GET` | `/tenants/:id/appointments` | Listar citas (`?from&to&includeCancelled`) |
| `POST` | `/tenants/:id/appointments` | Crear cita |
| `GET` | `/tenants/:id/knowledge` | Listar chunks de conocimiento |
| `POST` | `/tenants/:id/knowledge` | Crear chunk |
| `PUT` | `/tenants/:id/knowledge/:kId` | Actualizar chunk |
| `DELETE` | `/tenants/:id/knowledge/:kId` | Eliminar chunk |
| `GET` | `/tenants/:id/triggers` | Listar menu triggers |
| `POST` | `/tenants/:id/triggers` | Crear trigger |
| `DELETE` | `/tenants/:id/triggers/:tId` | Eliminar trigger |

---

### 8.2 Agenda — Públicos sin auth

Base: `AGENDA_API_BASE_URL` (ej. `http://localhost:8080/api/agenda`)

| Método | Endpoint | Método Dart | Descripción |
|---|---|---|---|
| `GET` | `/public/search?q=&tenantId=` | `search()` | Búsqueda de negocios por texto |
| `GET` | `/public/categories` | `listPublicCategories()` | Categorías activas |
| `GET` | `/public/categories/:slug/businesses?tenantId=` | `businessesByCategory()` | Negocios por categoría |
| `GET` | `/public/businesses/:id` | `publicBusinessDetail()` | Detalle público de negocio |
| `GET` | `/public/businesses/:id/services` | `publicBusinessServices()` | Servicios del negocio |

---

### 8.3 Agenda — Platform admin

| Método | Endpoint | Método Dart | Descripción |
|---|---|---|---|
| `GET` | `/platform/categories` | `listAllCategories()` | Todas las categorías (admin) |
| `POST` | `/platform/categories` | `createCategory()` | Crear categoría |
| `PUT` | `/platform/categories/:id` | `updateCategory()` | Actualizar categoría |
| `PUT` | `/platform/categories/:id/synonyms` | `mergeCategorySynonyms()` | Merge de sinónimos |
| `DELETE` | `/platform/categories/:id` | `deleteCategory()` | Eliminar categoría |

---

### 8.4 Agenda — Tenant features

| Método | Endpoint | Método Dart | Descripción |
|---|---|---|---|
| `GET` | `/tenants/:tenantId/features` | `getFeatures()` | Feature flags del tenant |
| `PUT` | `/tenants/:tenantId/features` | `updateFeatures()` | Actualizar feature flags |

---

### 8.5 Agenda — Tenant businesses

| Método | Endpoint | Método Dart | Descripción |
|---|---|---|---|
| `GET` | `/tenants/:tenantId/businesses` | `listBusinesses()` | Listar negocios del tenant |
| `POST` | `/tenants/:tenantId/businesses` | `createBusiness()` | Crear negocio |
| `PUT` | `/tenants/:tenantId/businesses/:businessId` | `updateBusiness()` | Actualizar negocio |
| `PUT` | `/tenants/:tenantId/businesses/:businessId/categories` | `associateCategories()` | Asociar categorías |
| `GET` | `/tenants/:tenantId/businesses/:businessId/settings` | `getSettings()` | Configuración del negocio |
| `PUT` | `/tenants/:tenantId/businesses/:businessId/settings` | `updateSettings()` | Actualizar configuración |

---

### 8.6 Agenda — Tenant services

| Método | Endpoint | Método Dart | Descripción |
|---|---|---|---|
| `GET` | `/tenants/:tenantId/businesses/:businessId/services` | `listTenantServices()` | Listar servicios (`?soloActivos=true`) |
| `POST` | `/tenants/:tenantId/businesses/:businessId/services` | `createService()` | Crear servicio |
| `PUT` | `/tenants/:tenantId/businesses/:businessId/services/:serviceId` | `updateService()` | Actualizar servicio |
| `DELETE` | `/tenants/:tenantId/businesses/:businessId/services/:serviceId` | `deleteService()` | Eliminar servicio |

---

### 8.7 Agenda — Tenant plans

| Método | Endpoint | Método Dart | Descripción |
|---|---|---|---|
| `GET` | `/tenants/:tenantId/businesses/:businessId/plans` | `listPlans()` | Listar planes (`?onlyActive=true`) |
| `POST` | `/tenants/:tenantId/businesses/:businessId/plans` | `createPlan()` | Crear plan |
| `PUT` | `/tenants/:tenantId/businesses/:businessId/plans/:planId` | `updatePlan()` | Actualizar plan |
| `DELETE` | `/tenants/:tenantId/businesses/:businessId/plans/:planId` | `deletePlan()` | Eliminar plan |

---

### 8.8 Agenda — Tenant loyalty

| Método | Endpoint | Método Dart | Descripción |
|---|---|---|---|
| `GET` | `/tenants/:tenantId/businesses/:businessId/loyalty/suggestions` | `listLoyaltySuggestions()` | Sugerencias de fidelización (`?estado=`) |
| `PATCH` | `/tenants/:tenantId/businesses/:businessId/loyalty/suggestions/:id` | `patchLoyaltySuggestion()` | Cambiar estado |
| `POST` | `/tenants/:tenantId/businesses/:businessId/loyalty/suggestions/:id/send` | `sendLoyaltySuggestion()` | Enviar sugerencia |

---

### 8.9 Agenda — Tenant notification templates

| Método | Endpoint | Método Dart | Descripción |
|---|---|---|---|
| `GET` | `/tenants/:tenantId/businesses/:businessId/templates` | `listTemplates()` | Listar plantillas |
| `POST` | `/tenants/:tenantId/businesses/:businessId/templates` | `createTemplate()` | Crear plantilla |
| `PUT` | `/tenants/:tenantId/businesses/:businessId/templates/:id` | `updateTemplate()` | Actualizar plantilla |
| `DELETE` | `/tenants/:tenantId/businesses/:businessId/templates/:id` | `deleteTemplate()` | Eliminar plantilla |

---

### 8.10 Agenda — Me subscriptions

Headers requeridos: `X-User-Id`.

| Método | Endpoint | Método Dart | Descripción |
|---|---|---|---|
| `POST` | `/tenants/:tenantId/businesses/:businessId/plans/:planId/subscribe` | `purchaseSubscription()` | Comprar suscripción |
| `GET` | `/me/subscriptions` | `mySubscriptions()` | Suscripciones del usuario (`?onlyActive=true`) |
| `GET` | `/me/subscriptions/:subscriptionId/wallet` | `myWallet()` | Wallet de una suscripción |

---

### 8.11 Agenda — Me bookings

Headers requeridos: `X-User-Id`. `createBooking` acepta `Idempotency-Key`.

| Método | Endpoint | Método Dart | Descripción |
|---|---|---|---|
| `POST` | `/tenants/:tenantId/businesses/:businessId/bookings` | `createBooking()` | Crear reserva |
| `GET` | `/me/bookings` | `myBookings()` | Reservas del usuario (`?tenantId&businessId&estado`) |
| `DELETE` | `/tenants/:tenantId/businesses/:businessId/bookings/:bookingId` | `cancelBooking()` | Cancelar reserva |

---

### 8.12 Agenda — Me notifications

Headers requeridos: `X-User-Id`.

| Método | Endpoint | Método Dart | Descripción |
|---|---|---|---|
| `GET` | `/me/notifications` | `myNotifications()` | Notificaciones del usuario (`?estado=`) |

---

## 9. Estructura de paquetes

```
frontend/lib/
├── main.dart                          # Punto de entrada, carga .env
├── core/
│   ├── config.dart                    # AppConfig — variables de entorno
│   ├── router.dart                    # GoRouter — todas las rutas
│   └── theme.dart                     # AppTheme (light / dark)
├── models/
│   ├── user.dart / bot.dart / ...     # Modelos del bot existente
│   └── agenda/                        # Modelos del módulo AGENDA
│       ├── business.dart
│       ├── business_summary.dart
│       ├── business_settings.dart
│       ├── category.dart
│       ├── agenda_service.dart
│       ├── plan.dart
│       ├── subscription.dart
│       ├── wallet.dart
│       ├── booking.dart
│       ├── loyalty_suggestion.dart
│       ├── notification_template.dart
│       ├── agenda_notification.dart
│       └── tenant_features.dart
├── services/
│   ├── api_service.dart               # HTTP client del bot
│   ├── agenda_api_service.dart        # HTTP client de AGENDA
│   └── agenda_api_exception.dart      # Excepción tipada de AGENDA
├── providers/
│   ├── auth_provider.dart             # Auth (Google Sign-In)
│   ├── bot_provider.dart              # Estado de bots
│   └── agenda/
│       ├── agenda_api_provider.dart   # Provider del AgendaApiService
│       ├── public/
│       │   ├── search_provider.dart
│       │   ├── public_categories_provider.dart
│       │   └── public_business_detail_provider.dart
│       ├── platform/
│       │   └── categories_admin_provider.dart
│       ├── tenant/
│       │   ├── businesses_provider.dart
│       │   ├── features_provider.dart
│       │   ├── services_provider.dart
│       │   ├── plans_provider.dart
│       │   ├── settings_provider.dart
│       │   ├── loyalty_provider.dart
│       │   └── templates_provider.dart
│       └── me/
│           ├── subscriptions_provider.dart
│           ├── wallet_provider.dart
│           ├── bookings_provider.dart
│           └── notifications_provider.dart
├── features/
│   ├── auth/login_screen.dart
│   ├── dashboard/dashboard_screen.dart
│   ├── bot_detail/bot_detail_screen.dart
│   └── agenda/
│       ├── agenda_landing_screen.dart
│       ├── theme/agenda_tokens.dart
│       ├── public/
│       │   ├── search_screen.dart
│       │   ├── category_businesses_screen.dart
│       │   └── public_business_detail_screen.dart
│       ├── platform/
│       │   └── categories_admin_screen.dart
│       ├── tenant/
│       │   ├── tenant_home_screen.dart
│       │   └── business_detail_screen.dart
│       └── me/
│           ├── my_subscriptions_screen.dart
│           ├── wallet_screen.dart
│           ├── my_bookings_screen.dart
│           ├── create_booking_screen.dart
│           └── my_notifications_screen.dart
└── widgets/
    ├── business_hours_card.dart       # Widget compartido del bot
    └── agenda/                        # Widgets del módulo AGENDA
```

---

## 10. State management — Riverpod providers

El estado global usa `flutter_riverpod`. Los providers más importantes:

| Provider | Archivo | Tipo | Descripción |
|---|---|---|---|
| `routerProvider` | `core/router.dart` | `Provider<GoRouter>` | Instancia del router |
| `authStateProvider` | `providers/auth_provider.dart` | `StateNotifierProvider` | Estado de autenticación |
| `agendaApiServiceProvider` | `providers/agenda/agenda_api_provider.dart` | `Provider<AgendaApiService>` | Cliente HTTP de AGENDA |
| `searchProvider` | `providers/agenda/public/search_provider.dart` | `FutureProvider.family` | Búsqueda pública |
| `publicCategoriesProvider` | `providers/agenda/public/public_categories_provider.dart` | `FutureProvider` | Categorías públicas |
| `businessesProvider` | `providers/agenda/tenant/businesses_provider.dart` | `StateNotifierProvider.family` | Negocios del tenant |
| `featuresProvider` | `providers/agenda/tenant/features_provider.dart` | `StateNotifierProvider.family` | Feature flags del tenant |
| `mySubscriptionsProvider` | `providers/agenda/me/subscriptions_provider.dart` | `FutureProvider` | Suscripciones del usuario |
| `myBookingsProvider` | `providers/agenda/me/bookings_provider.dart` | `StateNotifierProvider` | Reservas del usuario |

Usar providers en un widget:

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businesses = ref.watch(businessesProvider(tenantId));
    return businesses.when(
      data: (list) => ListView(...),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

---

## 11. Arquitectura y capas

```
Screen (features/)
   ↓  watch / read
Provider (providers/)
   ↓  llama
AgendaApiService (services/)
   ↓  HTTP
Backend /api/agenda/**
```

- **Screens**: solo UI y navegación. Sin lógica de negocio.
- **Providers**: transforman la respuesta de la API en estado observable.
- **AgendaApiService**: cliente HTTP puro, sin estado de UI.
- **Models**: POJOs inmutables con `fromJson` / `toJson`.
- `AgendaApiService` está aislado de `ApiService` — no comparten estado ni instancia.

---

## 12. Dependencias principales

| Paquete | Versión | Para qué |
|---|---|---|
| `flutter_riverpod` | ^2.6.1 | State management |
| `go_router` | ^14.6.2 | Navegación declarativa |
| `http` | ^1.2.2 | Llamadas HTTP |
| `google_sign_in` | ^6.2.1 | Auth con Google |
| `flutter_dotenv` | ^5.2.1 | Variables de entorno desde `.env` |
| `shared_preferences` | ^2.3.4 | Persistencia simple |
| `flutter_secure_storage` | ^9.2.4 | Almacenamiento seguro de tokens |
| `google_fonts` | ^6.2.1 | Tipografía |
| `flutter_svg` | ^2.0.17 | Íconos SVG |
| `cached_network_image` | ^3.4.1 | Imágenes con caché |
| `cupertino_icons` | ^1.0.8 | Íconos iOS |

Agregar nueva dependencia:

```bash
flutter pub add <paquete>
# o editar pubspec.yaml manualmente y luego:
flutter pub get
```
