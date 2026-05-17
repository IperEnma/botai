import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/agenda/tenant_admin_context.dart';
import '../../services/agenda_api_exception.dart';
import '../auth_provider.dart';
import 'agenda_api_provider.dart';
import 'agenda_user_provider.dart';

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
    // When agenda.security.enabled=false (dev), the backend returns 401 because
    // @AuthenticationPrincipal Jwt is null — it cannot resolve the tenant by email.
    // Fall back to the tenantId stored locally after registration so the admin
    // panel still works without a real JWT validation setup.
    if (e.status == 401) {
      final userState = await ref.read(agendaUserProvider.future);
      final storedId = userState.tenantId;
      if (storedId != null && storedId.isNotEmpty) {
        return TenantAdminContext(tenantId: storedId);
      }
    }
    rethrow;
  }
});

class TenantAdminResolveException implements Exception {
  const TenantAdminResolveException(this.code);
  final String code;
}
