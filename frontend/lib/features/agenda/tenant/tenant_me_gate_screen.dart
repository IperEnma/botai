import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/tenant_admin_resolved_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../services/agenda_api_exception.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../home/agenda_no_tenant_admin_screen.dart';

/// Resuelve el tenant del admin por email y redirige al primer negocio bajo
/// `/agenda/businesses/:businessId`. Si no tiene negocios va a `/agenda/onboarding`.
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
      data: (ctx) {
        final bizState = ref.watch(businessesProvider(ctx.tenantId));

        if (bizState.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFFBFAF7),
            body: AgendaLoadingView(),
          );
        }

        if (bizState.error != null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFBFAF7),
            body: AgendaErrorView(
              message: bizState.error!,
              onRetry: () =>
                  ref.read(businessesProvider(ctx.tenantId).notifier).load(),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (bizState.items.isNotEmpty) {
            context.go('/agenda/businesses/${bizState.items.first.id}');
          } else {
            context.go('/agenda/onboarding');
          }
        });

        return const Scaffold(
          backgroundColor: Color(0xFFFBFAF7),
          body: AgendaLoadingView(),
        );
      },
    );
  }
}
