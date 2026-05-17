import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/agenda/agenda_api_provider.dart';
import '../providers/agenda/tenant_admin_resolved_provider.dart';
import '../providers/auth_provider.dart';
import 'router.dart';
import 'router_refresh.dart';

/// Tras autenticación: token Agenda + `/home` (el gate decide panel u onboarding).
void navigateAfterAuthenticatedSession(WidgetRef ref) {
  final auth = ref.read(authStateProvider);
  final user = auth.user;
  if (!auth.isAuthenticated || user == null || user.email.isEmpty) {
    return;
  }

  ref.read(agendaApiServiceProvider).setAccessToken(user.accessToken);
  ref.invalidate(tenantAdminResolvedProvider);
  ref.read(routerRefreshListenableProvider).refresh();

  final router = ref.read(routerProvider);
  final loc = router.routerDelegate.currentConfiguration.uri.path;
  if (loc == '/login' || loc == '/') {
    router.go('/home');
  }
}
