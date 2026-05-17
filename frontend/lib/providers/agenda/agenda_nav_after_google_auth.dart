import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/agenda_api_exception.dart';
import '../auth_provider.dart';
import 'agenda_api_provider.dart';
import 'agenda_user_provider.dart';
import 'tenant_admin_resolved_provider.dart';

/// Tras Google Sign-In:
/// - tenant existe + tiene negocio → `/agenda/businesses/:firstBusinessId`
/// - tenant existe + sin negocio  → `/agenda/onboarding`
/// - sin tenant (404 o 401)       → guarda datos y va a `/agenda/onboarding`
///
/// El 401 se trata igual que 404 porque cuando [agenda.security.enabled=false] (dev local)
/// el controller no puede extraer el JWT y devuelve 401.
Future<void> agendaNavigateAfterGoogleSignIn(
  WidgetRef ref,
  BuildContext context,
) async {
  final auth = ref.read(authStateProvider);
  final user = auth.user;
  debugPrint('[NAV] agendaNavigateAfterGoogleSignIn — email=${user?.email}');
  if (user == null || user.email.isEmpty) {
    debugPrint('[NAV] abortando: sin usuario autenticado');
    return;
  }

  final api = ref.read(agendaApiServiceProvider);
  api.setAccessToken(user.accessToken);
  ref.invalidate(tenantAdminResolvedProvider);

  // ── Paso 1: verificar si el tenant existe ────────────────────────────────
  String tenantId;
  try {
    final ctx = await api.fetchTenantAdminContext();
    tenantId = ctx.tenantId;
    debugPrint('[NAV] fetchTenantAdminContext → tenantId=$tenantId');
  } on AgendaApiException catch (e) {
    debugPrint('[NAV] fetchTenantAdminContext error → status=${e.status} isNotFound=${e.isNotFound}');
    if (!context.mounted) return;
    // 404 = nuevo usuario; 401 en dev local (security deshabilitado) = igual que 404
    if (!e.isNotFound && e.status != 401) {
      debugPrint('[NAV] error inesperado al verificar tenant: ${e.message}');
      return;
    }
    // Usuario nuevo: guarda datos y va al onboarding
    final trimmedName = user.name?.trim();
    final nombre = (trimmedName != null && trimmedName.isNotEmpty)
        ? trimmedName
        : user.email.split('@').first;
    await ref.read(agendaUserProvider.notifier).saveGoogleRegistration(
          nombre: nombre,
          email: user.email,
        );
    if (!context.mounted) return;
    debugPrint('[NAV] usuario nuevo → /agenda/onboarding');
    context.go('/agenda/onboarding');
    return;
  } catch (e) {
    debugPrint('[NAV] fetchTenantAdminContext excepción inesperada: $e');
    return;
  }

  // ── Paso 2: verificar si ya tiene negocio ────────────────────────────────
  if (!context.mounted) return;
  try {
    final businesses = await api.listBusinesses(tenantId);
    debugPrint('[NAV] listBusinesses → ${businesses.length} negocios');
    if (!context.mounted) return;
    final destination = businesses.isNotEmpty
        ? '/agenda/businesses/${businesses.first.id}'
        : '/agenda/onboarding';
    debugPrint('[NAV] context.go($destination)');
    context.go(destination);
  } catch (e) {
    debugPrint('[NAV] listBusinesses error: $e → /agenda/onboarding');
    if (!context.mounted) return;
    context.go('/agenda/onboarding');
  }
}
