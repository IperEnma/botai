import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/agenda/tenant_admin_context.dart';
import '../../services/agenda_api_exception.dart';
import '../auth_provider.dart';
import 'agenda_api_provider.dart';

final tenantAdminResolvedProvider =
    FutureProvider.autoDispose<TenantAdminContext>((ref) async {
  final auth = ref.watch(authStateProvider);
  if (!auth.isAuthenticated ||
      auth.user?.email == null ||
      auth.user!.email.isEmpty) {
    throw const TenantAdminResolveException('NOT_AUTHENTICATED');
  }
  final api = ref.watch(agendaApiServiceProvider);
  try {
    return await api.fetchTenantAdminContext();
  } on AgendaApiException catch (e) {
    if (e.status == 401) {
      // Token Google inválido o vencido (p. ej. volvió del flujo público de reserva).
      await ref.read(authStateProvider.notifier).signOut();
      throw const TenantAdminResolveException('NOT_AUTHENTICATED');
    }
    rethrow;
  }
});

class TenantAdminResolveException implements Exception {
  const TenantAdminResolveException(this.code);
  final String code;
}
