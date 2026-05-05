# Plan técnico — Frontend **AGENDA** (Flutter)

> Plan de implementación del frontend del módulo **AGENDA** sobre el proyecto Flutter existente (`frontend/`). Se ejecuta **sin modificar** ninguna pantalla, modelo, provider o service del bot actual. Este documento es solo **propuesta de plan** — no implementa aún.

---

## 0. Decisiones de arquitectura acordadas

| Dimensión | Decisión |
|---|---|
| Proyecto | **Mismo `pubspec.yaml`** que el bot (`frontend/botai_admin`). No se crea un artefacto nuevo. |
| Acoplamiento con el bot | **Cero cambios** en `lib/features/{auth, dashboard, bot_config, bot_detail, menus, knowledge, services, appointments}`, `lib/models/{bot,menu,knowledge,service,appointment,user}.dart`, `lib/services/{api_service,auth_service}.dart`, `lib/providers/{auth_provider,bot_provider}.dart`. |
| Reutilización | `lib/core/theme.dart` (paleta) y `lib/providers/auth_provider.dart` (login Google) se consumen **solo-lectura**. |
| Única modificación admitida sobre código del bot | Agregar rutas `/agenda/**` en `lib/core/router.dart` (equivalente a agregar keys `agenda:` en `application.yml` del backend) y un acceso al módulo desde el dashboard (botón/tile). |
| Stack | Flutter 3.11, Material 3, `flutter_riverpod 2.6`, `go_router 14.6`, `http`, `google_fonts` (Inter). **No se suman dependencias nuevas en Sprint 1.** |
| Target | Web primero (ya hay `run-web.ps1` en puerto 5000). Mobile queda habilitado por diseño responsive pero no se certifica en este plan. |
| Alcance | Frontend AGENDA, Sprint FE-1 a FE-3. Push notifications y PWA offline quedan fuera. |

---

## 1. Visión arquitectónica

El frontend AGENDA replica la arquitectura por features del bot, pero vive en un **subárbol paralelo** bajo `lib/features/agenda/`. Las capas son:

- **`lib/models/agenda/`** — clases de datos inmutables con `fromJson` / `toJson` (espejan los DTOs del backend).
- **`lib/services/agenda_api_service.dart`** — único cliente HTTP contra `/api/agenda/**`. No usa `ApiService` del bot.
- **`lib/providers/agenda/`** — providers Riverpod (`StateNotifier` o `AsyncNotifier`) por feature.
- **`lib/features/agenda/**`** — screens + widgets locales organizados por **scope** del backend: `public`, `platform`, `tenant`, `me`.
- **`lib/widgets/agenda/`** — widgets reutilizables cross-feature del módulo (cards de negocio, chips de categoría, etc.). Nunca se fusionan con `lib/widgets/` del bot.

### 1.1 Nueva estructura de carpetas

Vista **macro** — el bot existente queda intocado; AGENDA vive en paralelo:

```
lib/
├── main.dart                         # INTOCADO
├── core/                             # theme + config intocados; router extendido
├── models/                           # INTOCADO
│   └── agenda/                       # NUEVO
├── services/                         # api_service.dart INTOCADO
│   └── agenda_api_service.dart       # NUEVO
├── providers/                        # auth_provider, bot_provider INTOCADOS
│   └── agenda/                       # NUEVO
├── features/
│   ├── [bot features]                # INTOCADAS
│   └── agenda/                       # NUEVO
└── widgets/
    ├── business_hours_card.dart      # INTOCADO
    └── agenda/                       # NUEVO
```

Vista **detallada** de `lib/features/agenda/`:

```
lib/features/agenda/
├── public/
│   ├── search_screen.dart               # /agenda/public/search
│   ├── business_detail_screen.dart      # /agenda/public/business/:id
│   └── widgets/
│       ├── category_chip.dart
│       └── business_summary_card.dart
├── platform/
│   ├── categories_screen.dart           # /agenda/platform/categories
│   └── widgets/
│       └── category_form_dialog.dart
├── tenant/
│   ├── tenant_home_screen.dart          # /agenda/tenants/:tenantId (shell)
│   ├── businesses_screen.dart
│   ├── business_detail_screen.dart      # detalle admin (con tabs internos)
│   ├── tabs/
│   │   ├── services_tab.dart
│   │   ├── plans_tab.dart
│   │   ├── categories_tab.dart
│   │   ├── settings_tab.dart
│   │   ├── loyalty_tab.dart
│   │   └── templates_tab.dart
│   ├── features_screen.dart             # toggles de feature flags
│   └── widgets/
│       ├── plan_form_dialog.dart
│       ├── service_form_dialog.dart
│       ├── loyalty_suggestion_card.dart
│       └── template_form_dialog.dart
└── me/
    ├── my_subscriptions_screen.dart     # /agenda/me/subscriptions
    ├── wallet_screen.dart               # /agenda/me/subscriptions/:id/wallet
    ├── my_bookings_screen.dart          # /agenda/me/bookings
    ├── create_booking_screen.dart
    ├── my_notifications_screen.dart     # /agenda/me/notifications
    └── widgets/
        ├── subscription_card.dart
        ├── wallet_transaction_tile.dart
        └── booking_card.dart
```

### 1.2 Aislamiento respecto al bot

Reglas innegociables:

1. Ningún archivo bajo `lib/features/agenda/**` importa clases de `lib/features/{bot_config, bot_detail, menus, knowledge, services, appointments}` ni de `lib/providers/bot_provider.dart` ni de `lib/services/api_service.dart` ni de `lib/models/{bot,menu,knowledge,service,appointment}.dart`.
2. Se puede importar desde AGENDA: `lib/core/theme.dart`, `lib/core/config.dart`, `lib/providers/auth_provider.dart` (solo-lectura), `lib/models/user.dart`.
3. `lib/core/router.dart` crece con rutas `/agenda/**` pero **no se reescriben** las rutas del bot (solo se suman).
4. Un test de análisis estático (`dart analyze` + convención de review) valida estas reglas en cada PR.

---

## 2. Paleta y sistema visual (reutilizado del bot)

Se consume `AppTheme` existente sin modificaciones. Colores:

| Token | Valor | Uso en AGENDA |
|---|---|---|
| `primaryColor` | `#6366F1` | CTAs principales, links, botones de acción |
| `secondaryColor` | `#8B5CF6` | Gradiente del branding, estados activos |
| `accentColor` | `#22D3EE` | Destacados (badge VIP, tier GOLDEN) |
| `backgroundColor` | `#F8FAFC` | Fondo scaffold |
| `surfaceColor` | `white` | Cards, diálogos |
| `successColor` | `#22C55E` | Booking CONFIRMED, notificación SENT |
| `errorColor` | `#EF4444` | Booking CANCELLED, saldo insuficiente |
| Gradiente | `primaryColor → secondaryColor` | Header de login / shell del módulo |

Tipografía: `GoogleFonts.inter` ya aplicada globalmente.

Tokens adicionales específicos de AGENDA (declarados en `lib/features/agenda/theme/agenda_tokens.dart`):

```dart
class AgendaTokens {
  static const Color tierVip = Color(0xFFF59E0B);     // amber-500
  static const Color tierGolden = Color(0xFFEAB308);  // yellow-500
  static const Color tierPlata = Color(0xFF94A3B8);   // slate-400
  static const Color creditPositive = Color(0xFF22C55E);
  static const Color creditNegative = Color(0xFFEF4444);
  static const double cardRadius = 16.0;
  static const double chipRadius = 20.0;
}
```

Nada de esto toca `AppTheme`.

---

## 3. Modelos (`lib/models/agenda/`)

Espejan 1-a-1 los DTOs del backend. Convención de archivos: un archivo por agregado, nombres en `snake_case.dart` con clase en `PascalCase`.

| Archivo | Clase | Campos clave |
|---|---|---|
| `category.dart` | `Category` | id, nombre, slug, synonyms, activo |
| `business_summary.dart` | `BusinessSummary` | id, nombre, descripcion, categorias, activo |
| `business.dart` | `Business` | id, tenantId, nombre, descripcion, searchTags, activo |
| `business_settings.dart` | `BusinessSettings` | businessId, hoursCancellationLimit, loyaltyMinAttendances, loyaltyWindowDays, expirationAlertDays, expirationAlertCredits, autoNotifyEnabled |
| `agenda_service.dart` | `AgendaService` | id, businessId, nombre, descripcion, duracionMin, precio, activo |
| `plan.dart` | `Plan` + enums `PlanTipo`/`PlanTier` | id, nombrePlan, tipo, tier, totalCreditos, validezDias, precio, activo |
| `subscription.dart` | `Subscription` + enum `SubscriptionEstado` | id, userId, planId, businessId, saldoActual, fechaInicio, fechaExpiracion, estado |
| `wallet.dart` | `Wallet` + `CreditTransaction` | subscriptionId, saldoActual, fechaExpiracion, movimientos |
| `booking.dart` | `Booking` + enum `BookingEstado` | id, userId, serviceId, businessId, subscriptionId, fechaHoraInicio, fechaHoraFin, estado, tipoReserva |
| `loyalty_suggestion.dart` | `LoyaltySuggestion` + enum `LoyaltySuggestionEstado` | id, businessId, userId, triggerRule, estado, createdAt |
| `notification_template.dart` | `NotificationTemplate` + enum `NotificationCanal` | id, businessId, codigo, canal, titulo, cuerpo |
| `agenda_notification.dart` | `AgendaNotification` + enum `NotificationEstado` | id, businessId, canal, titulo, cuerpo, estado, createdAt |
| `tenant_features.dart` | `TenantFeatures` | tenantId, agendaEnabled, publicSearchEnabled, loyaltyEngineEnabled, autoNotifications |

> **Por qué el prefijo `Agenda` en algunos nombres:** `Service` y `Notification` colisionarían con clases existentes del bot (`models/service.dart`) o de Flutter (`Notification` es un símbolo común). El prefijo evita ambigüedad sin tocar imports del bot.

Todos los modelos son `@immutable` (constructor `const` cuando es posible), con `copyWith`, `==`/`hashCode` manual (no se suma `freezed` en Sprint 1) y `fromJson` defensivo (tolerante a nulls, replicando el patrón de `Bot.fromJson`).

---

## 4. Servicio HTTP (`lib/services/agenda_api_service.dart`)

Una sola clase `AgendaApiService`, paralela a `ApiService` del bot. Firma mínima:

```dart
class AgendaApiService {
  final String baseUrl;           // http://localhost:8080/api/agenda
  String? _accessToken;
  String? _userId;                // para header X-User-Id

  void setAccessToken(String? token);
  void setUserId(String? userId);

  // Público
  Future<List<BusinessSummary>> search({required String q, required String tenantId});
  Future<List<Category>> listPublicCategories();
  Future<List<BusinessSummary>> businessesByCategory(String slug, String tenantId);
  Future<Business> publicBusinessDetail(String id);
  Future<List<AgendaService>> publicBusinessServices(String id);

  // Platform
  Future<List<Category>> listAllCategories();
  Future<Category> createCategory(CategoryInput input);
  Future<Category> updateCategory(String id, CategoryInput input);
  Future<Category> mergeSynonyms(String id, List<String> synonyms);
  Future<void> deleteCategory(String id);

  // Tenant - features
  Future<TenantFeatures> getFeatures(String tenantId);
  Future<TenantFeatures> updateFeatures(String tenantId, TenantFeaturesInput input);

  // Tenant - businesses
  Future<List<Business>> listBusinesses(String tenantId);
  Future<Business> createBusiness(String tenantId, BusinessInput input);
  Future<Business> updateBusiness(String tenantId, String businessId, BusinessInput input);
  Future<void> associateCategories(String tenantId, String businessId, List<String> categoryIds);
  Future<BusinessSettings> getSettings(String tenantId, String businessId);
  Future<BusinessSettings> updateSettings(String tenantId, String businessId, BusinessSettings input);

  // Tenant - services
  Future<List<AgendaService>> listServices(String tenantId, String businessId, {bool soloActivos = false});
  Future<AgendaService> createService(String tenantId, String businessId, ServiceInput input);
  Future<AgendaService> updateService(String tenantId, String businessId, String serviceId, ServiceInput input);
  Future<void> deleteService(String tenantId, String businessId, String serviceId);

  // Tenant - plans
  Future<List<Plan>> listPlans(String tenantId, String businessId, {bool onlyActive = false});
  Future<Plan> createPlan(String tenantId, String businessId, PlanInput input);
  Future<Plan> updatePlan(String tenantId, String businessId, String planId, PlanInput input);
  Future<void> deletePlan(String tenantId, String businessId, String planId);

  // Tenant - loyalty
  Future<List<LoyaltySuggestion>> listLoyaltySuggestions(String tenantId, String businessId, {LoyaltySuggestionEstado? estado});
  Future<LoyaltySuggestion> patchLoyaltySuggestion(String tenantId, String businessId, String id, LoyaltySuggestionEstado estado);
  Future<LoyaltySuggestion> sendLoyaltySuggestion(String tenantId, String businessId, String id);

  // Tenant - templates
  Future<List<NotificationTemplate>> listTemplates(String tenantId, String businessId);
  Future<NotificationTemplate> createTemplate(String tenantId, String businessId, TemplateInput input);
  Future<NotificationTemplate> updateTemplate(String tenantId, String businessId, String id, TemplateInput input);
  Future<void> deleteTemplate(String tenantId, String businessId, String id);

  // Me - subscriptions
  Future<Subscription> purchaseSubscription(String tenantId, String businessId, String planId);
  Future<List<Subscription>> mySubscriptions({bool onlyActive = false});
  Future<Wallet> myWallet(String subscriptionId);

  // Me - bookings
  Future<Booking> createBooking(String tenantId, String businessId, CreateBookingInput input, {String? idempotencyKey});
  Future<List<Booking>> myBookings(String tenantId, String businessId, {BookingEstado? estado});
  Future<void> cancelBooking(String tenantId, String businessId, String bookingId);

  // Me - notifications
  Future<List<AgendaNotification>> myNotifications({NotificationEstado? estado});
}
```

**Políticas cross-cutting del cliente:**

- Todas las llamadas bajo `/me/**` añaden `X-User-Id: <uuid>` automáticamente si `_userId != null`.
- POST a `/me/.../bookings` genera un `Idempotency-Key` UUID v4 por request (nuevo por intento explícito, reutilizado en reintentos silenciosos — ver Sprint FE-3).
- Errores 4xx parsean el body JSON `{ code, message }` del backend y lanzan `AgendaApiException(code, message, status)` tipada que los providers traducen a mensajes i18n.
- Timeout de 15s por request (mismo que el bot) vía `http.Client` envuelto.
- `_accessToken` se rellena desde `authStateProvider` (bot) en el arranque.

---

## 5. State management (`lib/providers/agenda/`)

Un provider por feature + un `agendaApiServiceProvider` raíz. Nada de state global compartido con el bot.

```
lib/providers/agenda/
├── agenda_api_provider.dart           # Provider<AgendaApiService> singleton
├── agenda_user_context_provider.dart  # Provider<String?> — userId efectivo (de auth o de X-User-Id manual)
├── public/
│   ├── search_provider.dart           # StateNotifier con query + results + loading
│   └── categories_provider.dart       # FutureProvider<List<Category>>
├── platform/
│   └── categories_admin_provider.dart # StateNotifier CRUD
├── tenant/
│   ├── features_provider.dart
│   ├── businesses_provider.dart       # family<tenantId>
│   ├── services_provider.dart         # family<(tenantId, businessId)>
│   ├── plans_provider.dart
│   ├── settings_provider.dart
│   ├── loyalty_provider.dart
│   └── templates_provider.dart
└── me/
    ├── subscriptions_provider.dart
    ├── wallet_provider.dart
    ├── bookings_provider.dart
    └── notifications_provider.dart
```

**Convención:** los que hacen CRUD usan `StateNotifier<AsyncValue<List<T>>>`. Los read-only o derivados usan `FutureProvider` o `Provider`. Jamás se instancia `AgendaApiService` fuera de `agendaApiProvider`.

---

## 6. Rutas (`go_router`)

Se extiende el `routerProvider` existente agregando una **segunda `ShellRoute`** dedicada a AGENDA. La shell del bot queda sin cambios.

| Scope | Ruta | Screen |
|---|---|---|
| Público | `/agenda/public/search` | `SearchScreen` |
| Público | `/agenda/public/categories/:slug` | `CategoryBusinessesScreen` |
| Público | `/agenda/public/business/:id` | `PublicBusinessDetailScreen` |
| Platform | `/agenda/platform/categories` | `CategoriesAdminScreen` |
| Tenant | `/agenda/tenants/:tenantId` | `TenantHomeScreen` (shell con sidebar local) |
| Tenant | `/agenda/tenants/:tenantId/features` | `FeaturesScreen` |
| Tenant | `/agenda/tenants/:tenantId/businesses` | `BusinessesScreen` |
| Tenant | `/agenda/tenants/:tenantId/businesses/:businessId` | `BusinessDetailScreen` (con tabs internos: services, plans, settings, categories, loyalty, templates) |
| Me | `/agenda/me/subscriptions` | `MySubscriptionsScreen` |
| Me | `/agenda/me/subscriptions/:id/wallet` | `WalletScreen` |
| Me | `/agenda/me/bookings` | `MyBookingsScreen` |
| Me | `/agenda/me/bookings/new?businessId=...` | `CreateBookingScreen` |
| Me | `/agenda/me/notifications` | `MyNotificationsScreen` |

**Entry point:** en el dashboard del bot (`/dashboard`) se añade un tile/botón "Agenda" — **única modificación a una pantalla del bot**. Alternativa: una ruta top-level `/agenda` con un landing que permite elegir scope (más neutral, no toca el dashboard). Queda a validar en el checklist.

**Guards:**
- `/agenda/platform/**` exige rol `PLATFORM_ADMIN` (cuando auth esté listo; por ahora un flag en `.env`).
- `/agenda/tenants/:tenantId/**` exige sesión activa + que el usuario pertenezca al tenant.
- `/agenda/me/**` exige sesión activa; si no hay `userId` en contexto, redirige a login.
- `/agenda/public/**` sin guard.

Todas las rutas respetan el backend flag `AGENDA_ENABLED`: si una API devuelve 404 del guard, el frontend muestra una pantalla "Agenda no disponible para este tenant" en vez de un error crudo.

---

## 7. Pantallas por scope (detalle)

### 7.1 Público

- **`SearchScreen`**: barra de búsqueda con debounce 300 ms, chips horizontales de categorías (tap → filtra), resultados como `BusinessSummaryCard` en grilla responsive (1 col mobile, 2 col tablet, 3 col desktop). Estado vacío amigable. Tap a una card → `PublicBusinessDetailScreen`.
- **`CategoryBusinessesScreen`**: misma grilla filtrada por slug, título = nombre de la categoría.
- **`PublicBusinessDetailScreen`**: header con gradiente primary→secondary, descripción, lista de categorías (chips), lista de servicios (nombre, duración, precio). Sin botón "reservar" (eso pertenece a `/me`).

### 7.2 Platform admin

- **`CategoriesAdminScreen`**: tabla de categorías con columnas nombre/slug/synonyms/activo, botones editar/eliminar, FAB "Nueva categoría". `CategoryFormDialog` maneja create/update. Edición de sinónimos con chips + input. `DELETE` confirma con `AlertDialog` y muestra snackbar si el backend devuelve 409 (categoría con negocios asociados).

### 7.3 Tenant admin

- **`TenantHomeScreen`**: shell con rail lateral (Negocios, Feature flags). Cabecera con nombre del tenant.
- **`FeaturesScreen`**: cuatro `SwitchListTile` para los flags. Cambio optimista con rollback en error.
- **`BusinessesScreen`**: lista de negocios como cards; FAB "Nuevo negocio". Tap → `BusinessDetailScreen`.
- **`BusinessDetailScreen`**: tabs internos (`TabBar`): **Info** (nombre, descripción, searchTags editables), **Categorías** (multi-select contra catálogo global), **Servicios** (CRUD), **Planes** (CRUD), **Settings** (form con todos los campos de `BusinessSettings`), **Loyalty** (lista de sugerencias + acciones), **Templates** (CRUD de plantillas).

### 7.4 Usuario final

- **`MySubscriptionsScreen`**: cards con plan, negocio, saldo, fecha vencimiento y badge de estado. Filtro "solo activas". Tap → `WalletScreen`.
- **`WalletScreen`**: header con saldo grande + fecha de expiración. Lista inversa cronológica de `CreditTransaction` (monto +/- con color según signo, motivo traducido, timestamp relativo).
- **`MyBookingsScreen`**: agrupado por fecha (`SliverStickyHeader`-like, pero con `GroupedListView` casero). Cada booking como card con servicio, negocio, hora, estado; tap largo → cancelar (con diálogo que advierte si está fuera de la ventana de cancelación).
- **`CreateBookingScreen`**: form con selector de servicio, selector de suscripción activa (o "pagar por turno"), `DateTimePicker`, notas opcionales. Valida en cliente contra la duración del servicio.
- **`MyNotificationsScreen`**: lista cronológica inversa. Tap marca como leída (`PUT` al backend si se agrega el endpoint futuro; por ahora solo visual).

---

## 8. Sprints (3 sprints)

### Sprint FE-1 — Base + Buscador público + Platform admin

**Objetivo:** un usuario sin login puede buscar negocios y el admin de plataforma puede gestionar el catálogo global.

Entregables:

1. Scaffolding de carpetas (`features/agenda/`, `models/agenda/`, `providers/agenda/`, `widgets/agenda/`, `theme/agenda_tokens.dart`).
2. `AgendaApiService` con los métodos de los endpoints `public/*` y `platform/*` (lista 4.1 y 4.1.1 del backend).
3. Modelos: `Category`, `BusinessSummary`, `Business`, `AgendaService` + enums de soporte.
4. Rutas `/agenda/public/**` y `/agenda/platform/categories`. Integración en `routerProvider` con ShellRoute propia.
5. Screens: `SearchScreen`, `CategoryBusinessesScreen`, `PublicBusinessDetailScreen`, `CategoriesAdminScreen` con su `CategoryFormDialog`.
6. Providers: `agendaApiServiceProvider`, `searchProvider`, `categoriesProvider`, `categoriesAdminProvider`.
7. Widgets reutilizables: `CategoryChip`, `BusinessSummaryCard`, `AgendaErrorView`, `AgendaEmptyState`.
8. Entry point en el dashboard del bot (o landing `/agenda`, a validar).
9. README del módulo en `frontend/lib/features/agenda/README.md`.
10. Tests widget: `SearchScreen` renderiza resultados mock; `CategoriesAdminScreen` valida create/delete flow.

**Historia cubierta:** "Búsqueda Inteligente" del lado cliente.

### Sprint FE-2 — Tenant admin completo

**Objetivo:** el dueño del negocio administra negocios, servicios, planes, categorías asociadas, settings y feature flags del tenant.

Entregables:

1. Rutas `/agenda/tenants/:tenantId/**` con `TenantHomeScreen` (shell local con rail).
2. Modelos faltantes: `Plan`, `BusinessSettings`, `TenantFeatures` + enums.
3. Screens: `FeaturesScreen`, `BusinessesScreen`, `BusinessDetailScreen` con tabs Info / Categorías / Servicios / Planes / Settings.
4. Widgets: `PlanFormDialog`, `ServiceFormDialog`, `BusinessFormDialog`, `CategoryMultiSelect`, `SettingsForm`.
5. Providers: `featuresProvider`, `businessesProvider.family`, `servicesProvider.family`, `plansProvider.family`, `settingsProvider.family`.
6. Manejo de errores por código: `BUSINESS_NOT_FOUND` → navega fuera; `INVALID_PLAN_CONFIGURATION` → resalta campo.
7. Tests widget: flujo `crear negocio → asociar categoría → crear plan → ver listado`.

**Historia cubierta:** "Control de Saldo" (lado configuración) + configuración de cancelación/loyalty/alertas.

### Sprint FE-3 — Usuario final + loyalty + notificaciones

**Objetivo:** un cliente compra una suscripción, reserva, consulta su billetera, recibe notificaciones. El admin del negocio gestiona sugerencias de loyalty y plantillas.

Entregables:

1. Rutas `/agenda/me/**`.
2. Modelos faltantes: `Subscription`, `Wallet`, `CreditTransaction`, `Booking`, `LoyaltySuggestion`, `NotificationTemplate`, `AgendaNotification`.
3. Screens me: `MySubscriptionsScreen`, `WalletScreen`, `MyBookingsScreen`, `CreateBookingScreen`, `MyNotificationsScreen`.
4. Screens tenant (tabs adicionales en `BusinessDetailScreen`): `LoyaltyTab`, `TemplatesTab`.
5. `CreateBookingScreen` genera `Idempotency-Key` por intento; si el usuario pulsa "Reintentar" en error de red, reutiliza la misma key.
6. `CancelBookingDialog` calcula en cliente si está dentro de la ventana y muestra advertencia clara antes de cancelar.
7. Providers: `subscriptionsProvider`, `walletProvider.family`, `bookingsProvider.family`, `notificationsProvider`, `loyaltyProvider.family`, `templatesProvider.family`.
8. Tests widget: `CreateBookingScreen` happy path + `SLOT_TAKEN`; `WalletScreen` muestra movimientos ordenados; `CancelBookingDialog` advierte correctamente dentro/fuera de ventana.

**Historias cubiertas:** "Control de Saldo" (lado consumo) + CU-01 (reserva) + CU-02 (notificaciones) + RF02, RF03, RF04, RF05, RF06.

---

## 9. Cobertura de requerimientos (frontend)

| ID | Requerimiento | Sprint | Dónde |
|---|---|---|---|
| RF01 | Buscador por sinónimos | FE-1 | `SearchScreen` + `SynonymSearchAdapter` del back |
| RF02 | Descuento automático al reservar | FE-3 | `CreateBookingScreen` → mostrar saldo antes/después |
| RF03 | Penalización por cancelación tardía | FE-3 | `CancelBookingDialog` |
| RF04 | Panel de fidelización | FE-3 | `LoyaltyTab` |
| RF05 | Notificaciones configurables | FE-3 | `TemplatesTab` + `MyNotificationsScreen` |
| RF06 | No reservas sin disponibilidad | FE-3 | `CreateBookingScreen` maneja `SLOT_TAKEN` |
| RNF01 | Búsqueda pública sin login | FE-1 | Rutas `/agenda/public/**` sin guard |
| RNF02 | Múltiples suscripciones por usuario | FE-3 | `MySubscriptionsScreen` lista N |

---

## 10. Testing

- **Widget tests** con `flutter_test` + `ProviderScope` override del `agendaApiProvider` (mock). Un archivo `_test.dart` por screen.
- **Golden tests** opcionales en Sprint FE-2 para `BusinessSummaryCard` y `WalletScreen` (congelar el layout).
- **Integration tests** con `integration_test` solo para el happy path end-to-end del buscador público (Sprint FE-3).
- **Cobertura objetivo:** 60% del código bajo `lib/features/agenda/` y `lib/providers/agenda/`.

Ubicación: `frontend/test/agenda/**` (espejo de `lib/features/agenda/**`). El test directory existente del bot queda intocado.

---

## 11. Configuración (`.env`)

Bloque nuevo para AGENDA, no modifica nada del bot:

```env
# Existente (bot) — NO SE TOCA
API_BASE_URL=http://localhost:8080/api
GOOGLE_CLIENT_ID_WEB=...

# Nuevo (agenda)
AGENDA_API_BASE_URL=http://localhost:8080/api/agenda
AGENDA_PLATFORM_ADMIN=false         # true = muestra el menú /agenda/platform
AGENDA_DEFAULT_TENANT_ID=            # dev only: tenant precargado sin login
```

> `AgendaApiService` lee `AGENDA_API_BASE_URL` con fallback a `${API_BASE_URL}/agenda`. Así en prod con un solo var alcanza.

---

## 12. Mejoras sugeridas (aportes al plan)

### Ahora (Sprint FE-1)
1. **`flutter_riverpod` code generation (`riverpod_generator`)** opcional — decide en el arranque de Sprint FE-1. Sin él los providers se escriben a mano; con él se gana type-safety. Sumar la dependencia solo si el equipo acepta el boilerplate adicional en CI.
2. **Logging HTTP** con un interceptor simple que imprime request/response en debug. Útil para demos.
3. **Responsive breakpoints unificados** (`lib/core/responsive.dart`) — mobile <600, tablet 600-1024, desktop >1024. El bot no lo tiene; se crea como util nuevo.

### Pronto (Sprint FE-2–3)
4. **Rate limit friendly UX** en el buscador público: si el back devuelve 429, mostrar "Intentá en un minuto" sin loop.
5. **Caché en memoria con invalidación** para `categoriesProvider` (TTL 5 min). Hoy Riverpod ya lo hace con `keepAlive: true`; solo documentarlo.
6. **Manejo centralizado de errores** (`AgendaErrorMapper`) con mapeo `code → mensaje localizado`. Facilita i18n posterior.
7. **Telemetría de eventos de UI** (`agenda.search.submit`, `agenda.booking.create`, etc.) detrás de un `AnalyticsPort` stub.
8. **Skeleton loaders** en vez de `CircularProgressIndicator` para cards.

### Backlog (fuera de plan)
9. **i18n completo** con `flutter_localizations` + `intl` — hoy todo en español hardcoded.
10. **Tema oscuro** — el bot ya lo tiene definido, AGENDA debería sumar las variantes de color específicas (VIP/GOLDEN/PLATA).
11. **App mobile nativa** (iOS/Android) — se deja para un plan aparte.
12. **Push notifications** — depende del `NotificationPort` real del backend.
13. **Offline-first** con `isar` o `hive` para billetera y notificaciones.

---

## 13. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Imports cruzados AGENDA ↔ bot (archivo de bot importado desde feature de agenda o viceversa) | Regla de review + script simple `grep -r "features/agenda" lib/features/bot_*` en pre-commit |
| Colisión de nombres de clase (`Service`, `Notification`) | Prefijo `Agenda` en los nombres colisionables + aliases en imports cuando haga falta |
| Divergencia de paleta si el bot cambia tokens | Reexportamos `AppTheme` intacto; AGENDA solo añade `AgendaTokens` encima, nunca re-define `primaryColor` |
| Backend flag `AGENDA_ENABLED=false` produce 404 no amigable | Interceptor HTTP traduce 404 en endpoints protegidos a una pantalla "Agenda no disponible" |
| `X-User-Id` manual antes de auth real | Documentar en README del módulo + `.env` con tenant/user de dev; tests con override |
| `@DirtiesContext`-like recarga de providers no se hace en Riverpod por default | En los tests se reinstancia `ProviderScope` por test con override; en runtime se confía en la lifecycle normal de providers |
| Web con puerto fijo 5000 (ver `run-web.ps1`) pisado por otro proceso | Documentar en README + fallback manual `--web-port=5001` |

---

## 14. Qué NO incluye este plan

- App mobile nativa certificada (iOS/Android).
- Push notifications reales (solo in-app).
- i18n (todo en español).
- Pagos reales (el backend usa `StubPaymentAdapter`; el frontend solo dispara el POST).
- Auth real: hasta que exista módulo de auth backend, se usa el `auth_provider` del bot para login + `X-User-Id` manual para pruebas.
- Analytics.
- Tema oscuro certificado para AGENDA.
- Refactor, rename o cleanup del código del bot.
- Cambios en `AppTheme`, `ApiService`, `AuthService` o cualquier screen del bot (salvo el tile de acceso al dashboard si se opta por esa vía).

---

## 15. Checklist antes de arrancar Sprint FE-1

- [ ] Aprobar este plan.
- [ ] Decidir si se suma `riverpod_generator` o se escriben providers a mano.
- [ ] Decidir entry point: tile en dashboard del bot vs landing `/agenda` neutral.
- [ ] Confirmar tokens adicionales (`tierVip`, `tierGolden`, `tierPlata`) y sus colores exactos.
- [ ] Confirmar que `AGENDA_API_BASE_URL` es aceptable como var nueva en `.env.example`.
- [ ] Crear tarjetas de seguimiento por sprint (FE-1, FE-2, FE-3) — 3 historias + subtareas.
- [ ] Decidir si Sprint FE-1 incluye un landing `/agenda` público o se entra directo a `/agenda/public/search`.

---

## 16. Flujo de trabajo sugerido

Por cada sprint:

1. **Diseño** — revisar este plan + backend (`PLAN_AGENDA.md`) y el endpoint exacto en `backend/docs/AGENDA_MODULE.md`.
2. **Scaffolding** — crear carpetas y archivos vacíos (screens, providers, modelos) para ver el mapa.
3. **Modelo + servicio** — primero los `fromJson`/`toJson` y los métodos del `AgendaApiService` usados por ese sprint.
4. **Providers** — encima del service.
5. **Screens** — arrancando por el "flujo feliz" con datos mock, después conectamos al provider real.
6. **Widget tests** — por cada screen.
7. **Manual smoke test** — con backend corriendo (`mvn spring-boot:run`) y `flutter run -d chrome --web-port=5000`.
8. **Review boundaries** — `grep` cruzado para asegurar que no hay imports del bot.

---

## 17. Referencias

- [PLAN_AGENDA.md](./PLAN_AGENDA.md) — plan backend.
- [backend/docs/AGENDA_MODULE.md](./backend/docs/AGENDA_MODULE.md) — endpoints, ejemplos `curl` y contratos.
- [CLAUDE.md](./CLAUDE.md) — reglas del repo.
- [frontend/pubspec.yaml](./frontend/pubspec.yaml) — stack actual.
- [frontend/lib/core/theme.dart](./frontend/lib/core/theme.dart) — paleta reutilizable.

---

**Siguiente paso sugerido:** revisar este plan, marcar las decisiones pendientes del checklist (§15) y, cuando estén resueltas, arrancar con el Sprint FE-1 — scaffolding + buscador público + admin de catálogo global.
