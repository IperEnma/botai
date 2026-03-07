import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/bot_detail/bot_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
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
        builder: (context, state, child) => AppShell(child: child, currentPath: state.matchedLocation),
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
