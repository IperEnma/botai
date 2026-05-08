import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/tenant_admin_resolved_provider.dart';
import '../../../services/agenda_api_exception.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../navigation/agenda_tenant_nav.dart';
import 'business_detail_screen.dart';

/// Detalle de negocio bajo `/home/businesses/:businessId` (tenant resuelto por cuenta).
class BusinessMeGateScreen extends ConsumerWidget {
  const BusinessMeGateScreen({
    super.key,
    required this.businessId,
    this.initialTabIndex = 0,
  });

  final String businessId;
  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(body: AgendaLoadingView());
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/home');
          });
          return const Scaffold(body: AgendaLoadingView());
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
        child: BusinessDetailScreen(
          tenantId: ctx.tenantId,
          businessId: businessId,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }
}
