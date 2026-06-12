import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/agenda/agenda_api_provider.dart';
import '../providers/agenda/me_profile_provider.dart';
import '../providers/auth_provider.dart';
import 'router.dart';
import 'router_refresh.dart';

/// Tras autenticación: token Agenda + gate que decide business panel o registro.
void navigateAfterAuthenticatedSession(WidgetRef ref) {
  final auth = ref.read(authStateProvider);
  final user = auth.user;
  if (!auth.isAuthenticated || user == null || user.email.isEmpty) {
    return;
  }

  ref.read(agendaApiServiceProvider).setAccessToken(user.accessToken);
  ref.invalidate(meProfileProvider);
  ref.read(routerRefreshListenableProvider).refresh();

  final router = ref.read(routerProvider);
  final loc = router.routerDelegate.currentConfiguration.uri.path;
  if (loc == '/login' || loc == '/' ||
      loc == '/agenda/register' || loc == '/agenda/onboarding') {
    router.go('/agenda/panel');
  }
}
