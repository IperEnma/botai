import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/agenda/tenant_admin_context.dart';
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
  return api.fetchTenantAdminContext();
});

class TenantAdminResolveException implements Exception {
  const TenantAdminResolveException(this.code);
  final String code;
}
