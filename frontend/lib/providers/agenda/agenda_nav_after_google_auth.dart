import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_provider.dart';
import 'agenda_api_provider.dart';
import 'tenant_admin_resolved_provider.dart';

/// Tras Google Sign-In: sincroniza el token Agenda y entra al panel (`/home`).
///
/// La resolución del tenant (cuenta existente vs onboarding) la hace
/// [TenantMeGateScreen] vía [tenantAdminResolvedProvider], en un solo lugar.
Future<void> agendaNavigateAfterGoogleSignIn(
  WidgetRef ref,
  BuildContext context,
) async {
  final auth = ref.read(authStateProvider);
  final user = auth.user;
  if (user == null || user.email.isEmpty) return;

  final api = ref.read(agendaApiServiceProvider);
  api.setAccessToken(user.accessToken);
  ref.invalidate(tenantAdminResolvedProvider);

  if (!context.mounted) return;
  context.go('/home');
}
