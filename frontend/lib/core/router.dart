import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/bot_detail/bot_detail_screen.dart';
// Agenda module — paquete paralelo, no toca el bot.
import '../features/agenda/agenda_landing_screen.dart';
import '../features/agenda/register/register_screen.dart';
import '../features/agenda/public/category_businesses_screen.dart';
import '../features/agenda/public/public_business_detail_screen.dart';
import '../features/agenda/public/search_screen.dart';
import '../features/agenda/public/landing_screen.dart';
import '../features/agenda/platform/categories_admin_screen.dart';
// Sprint FE-2 — Tenant admin
import '../features/agenda/tenant/tenant_home_screen.dart';
import '../features/agenda/tenant/business_detail_screen.dart';
// Sprint FE-3 — Me
import '../features/agenda/me/my_subscriptions_screen.dart';
import '../features/agenda/me/wallet_screen.dart';
import '../features/agenda/me/my_bookings_screen.dart';
import '../features/agenda/me/create_booking_screen.dart';
import '../features/agenda/me/my_notifications_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/agenda',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      // Durante período de testing, toda la sección /agenda es pública.
      // El bot del dashboard sigue requiriendo auth.
      final isAgendaRoute = state.matchedLocation.startsWith('/agenda');

      if (!isLoggedIn && !isLoggingIn && !isAgendaRoute) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/bot/:botId',
            builder: (context, state) {
              final botId = state.pathParameters['botId']!;
              return BotDetailScreen(botId: botId);
            },
          ),
        ],
      ),
      // ----------- AGENDA module -----------
      // Sin shell propio: cada screen maneja su AppBar. Más adelante (FE-2/3)
      // puede envolverse en una ShellRoute para mostrar rail lateral en /tenants/**.
      // Hub público principal — landing marketing
      GoRoute(
        path: '/agenda',
        builder: (context, state) => const PublicLandingScreen(),
      ),
      GoRoute(
        path: '/agenda/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/agenda/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Panel de onboarding (acceso post-login)
      GoRoute(
        path: '/agenda/onboarding',
        builder: (context, state) => const AgendaLandingScreen(),
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
        path: '/agenda/platform/categories',
        builder: (context, state) => const CategoriesAdminScreen(),
      ),
      // ----------- AGENDA — Tenant admin (Sprint FE-2) -----------
      GoRoute(
        path: '/agenda/tenants/:tenantId',
        builder: (context, state) {
          final tenantId = state.pathParameters['tenantId']!;
          return TenantHomeScreen(tenantId: tenantId);
        },
      ),
      GoRoute(
        path: '/agenda/tenants/:tenantId/businesses/:businessId',
        builder: (context, state) {
          final tenantId = state.pathParameters['tenantId']!;
          final businessId = state.pathParameters['businessId']!;
          return BusinessDetailScreen(
              tenantId: tenantId, businessId: businessId);
        },
      ),
      // ----------- AGENDA — Me (Sprint FE-3) -----------
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
              tenantId: tenantId, businessId: businessId);
        },
      ),
      GoRoute(
        path: '/agenda/me/notifications',
        builder: (context, state) => const MyNotificationsScreen(),
      ),
    ],
  );
});

class AppShell extends ConsumerWidget {
  final Widget child;
  final String currentPath;
  
  const AppShell({super.key, required this.child, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    final isInBotDetail = currentPath.startsWith('/bot/');
    
    if (isInBotDetail) {
      return child;
    }
    
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 0,
            onDestinationSelected: (index) {
              if (index == 0) context.go('/dashboard');
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text('BotAI', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user?.photoUrl != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(user!.photoUrl!),
                          radius: 20,
                        )
                      else
                        CircleAvatar(
                          radius: 20,
                          child: Text(user?.name?.substring(0, 1).toUpperCase() ?? 'U'),
                        ),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () {
                          ref.read(authStateProvider.notifier).signOut();
                          context.go('/login');
                        },
                        tooltip: 'Cerrar sesión',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Mis Bots'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
