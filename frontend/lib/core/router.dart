import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/bots/screens/bots_screen.dart';
import '../features/bot_detail/bot_detail_screen.dart';
// Agenda module — paquete paralelo, no toca el bot.
import '../features/agenda/register/register_screen.dart';
import '../features/agenda/register/business_register_screen.dart';
import '../features/agenda/register/register_success_screen.dart';
import '../features/agenda/register/intent_screen.dart';
import '../features/agenda/public/public_company_landing_screen.dart';
import '../features/agenda/public/public_mis_reservas_screen.dart';
import '../features/agenda/public/public_reservar_screen.dart';
import '../features/agenda/public/category_businesses_screen.dart';
import '../features/agenda/public/public_business_profile_screen.dart';
import '../features/agenda/public/search_screen.dart';
import '../features/agenda/public/landing_screen.dart';
import '../features/agenda/platform/categories_admin_screen.dart';
import '../features/agenda/home/agenda_home_shell.dart';
// Sprint FE-2 — Tenant admin
import '../features/agenda/tenant/agenda_panel_screen.dart';
import '../features/agenda/tenant/agenda_panel_section_screen.dart';
import '../features/agenda/tenant/agenda_panel_config_screen.dart';
import '../features/agenda/tenant/agenda_legacy_business_redirect.dart';
import '../features/agenda/tenant/mis_horarios_screen.dart';
// Sprint FE-3 — Me
import '../features/agenda/me/my_subscriptions_screen.dart';
import '../features/agenda/me/wallet_screen.dart';
import '../features/agenda/me/my_bookings_screen.dart';
import '../features/agenda/me/create_booking_screen.dart';
import '../features/agenda/me/my_notifications_screen.dart';
import 'router_refresh.dart';

/// Bookmarks y bundles viejos usaban `/home/**`; redirigimos sin pedir al usuario nada.
String? _legacyHomeRouteRedirect(GoRouterState state) {
  final loc = state.matchedLocation;
  final q = state.uri.query;
  String withQuery(String path) => q.isEmpty ? path : '$path?$q';

  if (loc == '/home/bots') return withQuery('/bots');
  if (loc.startsWith('/home/bots/')) {
    return withQuery('/bots${loc.substring('/home/bots'.length)}');
  }
  if (loc == '/home' || loc.startsWith('/home/')) {
    if (loc.startsWith('/home/businesses/')) {
      return withQuery('/agenda/panel');
    }
    return withQuery('/agenda/panel');
  }
  return null;
}

/// Page sin transición a nivel de `go_router`. El cross-fade lo aplica
/// `AgendaHomeShell` con un `AnimatedSwitcher`, así que todas las secciones
/// del shell se animan igual sin depender del tipo de navegación interna.
NoTransitionPage<T> _shellPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return NoTransitionPage<T>(key: key, child: child);
}

String? _normalizeTrailingSlash(GoRouterState state) {
  final path = state.uri.path;
  if (path.length <= 1 || !path.endsWith('/')) return null;
  final normalized = path.replaceAll(RegExp(r'/+$'), '');
  final q = state.uri.query;
  return q.isEmpty ? normalized : '$normalized?$q';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshListenableProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final slash = _normalizeTrailingSlash(state);
      if (slash != null) {
        return slash;
      }

      final legacy = _legacyHomeRouteRedirect(state);
      if (legacy != null) {
        return legacy;
      }

      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final loc = state.matchedLocation;
      final isLoggingIn = loc == '/login';
      final legacyTenantsMe = loc.startsWith('/agenda/tenants/me');
      final homeTenantArea =
          loc == '/agenda/panel' ||
          loc.startsWith('/agenda/panel/') ||
          loc.startsWith('/agenda/businesses/');
      final isPublicBookingRoute =
          loc == '/reservar' || loc.startsWith('/reservar/');
      final isAgendaRoute =
          loc == '/' || loc.startsWith('/agenda') || isPublicBookingRoute;

      if (isLoggedIn && loc == '/dashboard') {
        return '/bots';
      }
      if (!isLoggedIn && legacyTenantsMe) {
        return '/login';
      }
      if (!isLoggedIn && homeTenantArea) {
        return '/login';
      }
      if (!isLoggedIn && !isLoggingIn && !isAgendaRoute) {
        return '/login';
      }
      if (isLoggedIn && (loc == '/' || isLoggingIn ||
          loc == '/agenda/register' || loc == '/agenda/onboarding')) {
        return '/agenda/panel';
      }
      final meBizPrefix = '/agenda/tenants/me/businesses/';
      if (isLoggedIn && loc.startsWith(meBizPrefix)) {
        final after = loc.substring(meBizPrefix.length);
        final businessId =
            Uri.decodeComponent(after.split('?').first.split('/').first);
        final tab = state.uri.queryParameters['tab'];
        if (after.contains('/section/')) {
          final section = after.split('/section/').last.split('?').first;
          return '/agenda/businesses/$businessId/section/$section';
        }
        if (tab != null && tab.isNotEmpty) {
          return '/agenda/businesses/$businessId/config?tab=$tab';
        }
        return '/agenda/businesses/$businessId';
      }

      if (isLoggedIn && loc == '/agenda/tenants/me') {
        return '/agenda/panel';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AgendaHomeShell(
          locationKey: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/agenda/panel',
            pageBuilder: (context, state) {
              final section = state.uri.queryParameters['section'] ?? '';
              return _shellPage(
                key: ValueKey('/agenda/panel?section=$section'),
                child: const AgendaPanelScreen(),
              );
            },
          ),
          GoRoute(
            path: '/agenda/panel/config',
            pageBuilder: (context, state) {
              final tab =
                  int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
              return _shellPage(
                key: const ValueKey('/agenda/panel/config'),
                child: AgendaPanelConfigScreen(initialTabIndex: tab),
              );
            },
          ),
          GoRoute(
            path: '/agenda/panel/section/:section',
            pageBuilder: (context, state) {
              final section = state.pathParameters['section']!;
              return _shellPage(
                key: ValueKey('/agenda/panel/section/$section'),
                child: AgendaPanelSectionScreen(section: section),
              );
            },
          ),
          GoRoute(
            path: '/agenda/panel/mis-horarios',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey('/agenda/panel/mis-horarios'),
              child: const MisHorariosScreen(),
            ),
          ),
          GoRoute(
            path: '/agenda/businesses/:businessId',
            pageBuilder: (context, state) {
              final businessId = state.pathParameters['businessId']!;
              return _shellPage(
                key: ValueKey('/agenda/businesses/$businessId'),
                child: AgendaLegacyBusinessRedirect(
                  businessId: businessId,
                  targetPath: '/agenda/panel',
                ),
              );
            },
          ),
          GoRoute(
            path: '/agenda/businesses/:businessId/config',
            pageBuilder: (context, state) {
              final businessId = state.pathParameters['businessId']!;
              final tab = state.uri.queryParameters['tab'];
              final target = tab != null && tab.isNotEmpty
                  ? '/agenda/panel/config?tab=$tab'
                  : '/agenda/panel/config';
              return _shellPage(
                key: ValueKey('/agenda/businesses/$businessId/config'),
                child: AgendaLegacyBusinessRedirect(
                  businessId: businessId,
                  targetPath: target,
                ),
              );
            },
          ),
          GoRoute(
            path: '/agenda/businesses/:businessId/section/:section',
            pageBuilder: (context, state) {
              final businessId = state.pathParameters['businessId']!;
              final section = state.pathParameters['section']!;
              return _shellPage(
                key: ValueKey(
                    '/agenda/businesses/$businessId/section/$section'),
                child: AgendaLegacyBusinessRedirect(
                  businessId: businessId,
                  targetPath: '/agenda/panel/section/$section',
                ),
              );
            },
          ),
          GoRoute(
            path: '/bots',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey('/bots'),
              child: const BotsScreen(),
            ),
          ),
          GoRoute(
            path: '/bots/:botId',
            pageBuilder: (context, state) {
              final botId = state.pathParameters['botId']!;
              return _shellPage(
                key: ValueKey('/bots/$botId'),
                child: BotDetailScreen(botId: botId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/bot/:botId',
        redirect: (context, state) {
          final botId = state.pathParameters['botId']!;
          return '/bots/$botId';
        },
      ),
      // ----------- AGENDA module -----------
      GoRoute(
        path: '/',
        builder: (context, state) => const PublicLandingScreen(),
      ),
      GoRoute(
        path: '/reservar',
        builder: (context, state) {
          final company = state.uri.queryParameters['company'] ?? '';
          if (company.isEmpty) {
            return const PublicLandingScreen();
          }
          return PublicCompanyLandingScreen(companySlug: company);
        },
      ),
      GoRoute(
        path: '/reservar/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return PublicBusinessProfileScreen(slug: slug);
        },
        routes: [
          GoRoute(
            path: 'reservar',
            builder: (context, state) {
              final slug = state.pathParameters['slug']!;
              final company = state.uri.queryParameters['company'];
              return PublicReservarScreen(
                slug: slug,
                companySlug: company,
              );
            },
          ),
          GoRoute(
            path: 'mis-reservas',
            builder: (context, state) {
              final slug = state.pathParameters['slug']!;
              final company = state.uri.queryParameters['company'];
              return PublicMisReservasScreen(
                slug: slug,
                companySlug: company,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/agenda',
        redirect: (context, state) => '/agenda/search',
      ),
      GoRoute(
        path: '/agenda/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/agenda/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/agenda/business-register',
        builder: (context, state) => const BusinessRegisterScreen(),
      ),
      GoRoute(
        path: '/agenda/register-success',
        builder: (context, state) {
          final businessId = state.uri.queryParameters['businessId'] ?? '';
          return RegisterSuccessScreen(businessId: businessId);
        },
      ),
      GoRoute(
        path: '/agenda/onboarding',
        builder: (context, state) => const IntentScreen(),
      ),
      GoRoute(
        path: '/agenda/intent',
        redirect: (context, state) => '/agenda/onboarding',
      ),
      GoRoute(
        path: '/agenda/public/categories/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          final tenantId = state.uri.queryParameters['tenantId'] ?? '';
          return CategoryBusinessesScreen(slug: slug, tenantId: tenantId);
        },
      ),
      GoRoute(
        // Link público amigable → mismo flujo full-page que /reservar/:slug
        path: '/agenda/:slug',
        redirect: (context, state) {
          final slug = state.pathParameters['slug']!;
          final company = state.uri.queryParameters['company'];
          if (company != null && company.isNotEmpty) {
            return '/reservar/$slug?company=$company';
          }
          final q = state.uri.query;
          return q.isEmpty ? '/reservar/$slug' : '/reservar/$slug?$q';
        },
      ),
      GoRoute(
        path: '/agenda/platform/categories',
        builder: (context, state) => const CategoriesAdminScreen(),
      ),
      GoRoute(
        path: '/agenda/me/subscriptions',
        builder: (context, state) => const MySubscriptionsScreen(),
      ),
      GoRoute(
        path: '/agenda/me/subscriptions/:id/wallet',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WalletScreen(subscriptionId: id);
        },
      ),
      GoRoute(
        path: '/agenda/me/bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/agenda/me/bookings/new',
        builder: (context, state) {
          final tenantId = state.uri.queryParameters['tenantId'] ?? '';
          final businessId = state.uri.queryParameters['businessId'] ?? '';
          return CreateBookingScreen(
            tenantId: tenantId,
            businessId: businessId,
          );
        },
      ),
      GoRoute(
        path: '/agenda/me/notifications',
        builder: (context, state) => const MyNotificationsScreen(),
      ),
    ],
  );
});
