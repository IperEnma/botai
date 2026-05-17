import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/tenant_admin_resolved_provider.dart';
import '../../../services/agenda_api_exception.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../home/agenda_no_tenant_admin_screen.dart';
import '../navigation/agenda_tenant_nav.dart';
import 'tenant_home_screen.dart';

/// Resuelve el tenant del admin por email y muestra el mismo dashboard que
/// `/agenda/tenants/:tenantId`. La ruta principal es [`/home`].
class TenantMeGateScreen extends ConsumerWidget {
  const TenantMeGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(
        body: AgendaLoadingView(),
      );
    }

    final async = ref.watch(tenantAdminResolvedProvider);

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFFBFAF7),
        body: AgendaLoadingView(),
      ),
      error: (e, _) {
        if (e is TenantAdminResolveException &&
            e.code == 'NOT_AUTHENTICATED') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const Scaffold(body: AgendaLoadingView());
        }
        final notFound = e is AgendaApiException && e.isNotFound;
        if (notFound) {
          return Scaffold(
            backgroundColor: const Color(0xFFFBFAF7),
            body: AgendaNoTenantAdminScreen(
              onRetry: () => ref.invalidate(tenantAdminResolvedProvider),
            ),
          );
        }
        return Scaffold(
          backgroundColor: const Color(0xFFFBFAF7),
          body: AgendaErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(tenantAdminResolvedProvider),
          ),
        );
      },
      data: (ctx) => TenantNavScope(
        useMeRoutes: true,
        child: TenantHomeScreen(tenantId: ctx.tenantId),
      ),
    );
  }
}
