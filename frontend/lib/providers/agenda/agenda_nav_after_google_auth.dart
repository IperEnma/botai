import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router_refresh.dart';
import '../auth_provider.dart';
import 'agenda_api_provider.dart';
import 'tenant_admin_resolved_provider.dart';

/// Tras Google Sign-In: token Agenda + navegación al panel (`/home`).
///
/// Fuerza reevaluación del redirect de GoRouter y luego `go('/home')` en el
/// siguiente frame (evita carrera en el primer login móvil).
Future<void> agendaNavigateAfterGoogleSignIn(
  WidgetRef ref,
  BuildContext context,
) async {
  final auth = ref.read(authStateProvider);
  final user = auth.user;
  if (user == null || user.email.isEmpty || !auth.isAuthenticated) return;

  final api = ref.read(agendaApiServiceProvider);
  api.setAccessToken(user.accessToken);
  ref.invalidate(tenantAdminResolvedProvider);

  ref.read(routerRefreshListenableProvider).refresh();

  if (!context.mounted) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    final loc = router.routerDelegate.currentConfiguration.uri.path;
    if (loc != '/home' && !loc.startsWith('/home/')) {
      context.go('/home');
    }
  });
}
