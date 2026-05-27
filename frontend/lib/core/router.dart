import 'package:flutter/foundation.dart';
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
import '../features/agenda/public/category_businesses_screen.dart';
import '../features/agenda/public/public_business_detail_screen.dart';
import '../features/agenda/public/search_screen.dart';
import '../features/agenda/public/landing_screen.dart';
import '../features/agenda/platform/categories_admin_screen.dart';
import '../features/agenda/home/agenda_home_shell.dart';
// Sprint FE-2 — Tenant admin
import '../features/agenda/tenant/tenant_me_gate_screen.dart';
import '../features/agenda/tenant/business_me_gate_screen.dart';
import '../features/agenda/tenant/business_me_config_screen.dart';
import '../features/agenda/tenant/business_section_screen.dart';
// Sprint FE-3 — Me
import '../features/agenda/me/my_subscriptions_screen.dart';
import '../features/agenda/me/wallet_screen.dart';
import '../features/agenda/me/my_bookings_screen.dart';
import '../features/agenda/me/create_booking_screen.dart';
import '../features/agenda/me/my_notifications_screen.dart';
import 'router_refresh.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshListenableProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final loc = state.matchedLocation;
      final isLoggingIn = loc == '/login';
      final legacyTenantsMe = loc.startsWith('/agenda/tenants/me');
      final homeTenantArea =
          loc == '/agenda/panel' ||
          loc.startsWith('/agenda/businesses/');
      final isAgendaRoute = loc == '/' || loc.startsWith('/agenda');

      debugPrint('[ROUTER] redirect — loc=$loc isLoggedIn=$isLoggedIn');

      if (isLoggedIn && loc == '/dashboard') {
        debugPrint('[ROUTER] → /bots (dashboard)');
        return '/bots';
      }
      if (!isLoggedIn && legacyTenantsMe) {
        debugPrint('[ROUTER] → /login (legacyTenantsMe, not logged in)');
        return '/login';
      }
      if (!isLoggedIn && homeTenantArea) {
        debugPrint('[ROUTER] → /login (homeTenantArea, not logged in)');
        return '/login';
      }
      if (!isLoggedIn && !isLoggingIn && !isAgendaRoute) {
        debugPrint('[ROUTER] → /login (not agenda, not logged in)');
        return '/login';
      }
      if (isLoggedIn &&
          (loc == '/' || isLoggingIn || loc == '/agenda/register')) {
        return '/agenda/panel';
      }
      final meBizPrefix = '/agenda/tenants/me/businesses/';
      if (isLoggedIn && loc.startsWith(meBizPrefix)) {
        final after = loc.substring(meBizPrefix.length);
        final businessId =
            Uri.decodeComponent(after.split('?').first.split('/').first);
        final tab = state.uri.queryParameters['tab'];
        if (tab != null && tab.isNotEmpty) {
          return '/agenda/businesses/$businessId?tab=$tab';
        }
        return '/agenda/businesses/$businessId';
      }

      if (isLoggedIn && loc == '/agenda/tenants/me') {
        debugPrint('[ROUTER] → /agenda/panel (legacyTenantsMe, logged in)');
        return '/agenda/panel';
      }
      debugPrint('[ROUTER] → null (sin redirect)');
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AgendaHomeShell(child: child),
        routes: [
          GoRoute(
            path: '/agenda/panel',
            builder: (context, state) => const TenantMeGateScreen(),
          ),
          GoRoute(
            path: '/agenda/businesses/:businessId',
            builder: (context, state) {
              final businessId = state.pathParameters['businessId']!;
              return BusinessMeGateScreen(businessId: businessId);
            },
          ),
          GoRoute(
            path: '/agenda/businesses/:businessId/config',
            builder: (context, state) {
              final businessId = state.pathParameters['businessId']!;
              final tab =
                  int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
              return BusinessMeConfigScreen(
                businessId: businessId,
                initialTabIndex: tab,
              );
            },
          ),
          GoRoute(
            path: '/agenda/businesses/:businessId/section/:section',
            builder: (context, state) {
              final businessId = state.pathParameters['businessId']!;
              final section    = state.pathParameters['section']!;
              return BusinessSectionScreen(
                businessId: businessId,
                section:    section,
              );
            },
          ),
          GoRoute(
            path: '/bots',
            builder: (context, state) => const BotsScreen(),
          ),
          GoRoute(
            path: '/bots/:botId',
            builder: (context, state) {
              final botId = state.pathParameters['botId']!;
              return BotDetailScreen(botId: botId);
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
        path: '/agenda/public/business/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PublicBusinessDetailScreen(businessId: id);
        },
      ),
      GoRoute(
        // Link público amigable: debe ir DESPUÉS de /agenda/public/** para no capturarlo como slug.
        path: '/agenda/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return PublicBusinessDetailBySlugScreen(slug: slug);
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
