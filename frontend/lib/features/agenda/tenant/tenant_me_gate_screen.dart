import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import '../../../providers/agenda/tenant_admin_resolved_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../services/agenda_api_exception.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

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
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!context.mounted) return;
            final auth = ref.read(authStateProvider);
            final user = auth.user;
            if (auth.isAuthenticated && user != null && user.email.isNotEmpty) {
              final trimmedName = user.name?.trim();
              final nombre = (trimmedName != null && trimmedName.isNotEmpty)
                  ? trimmedName
                  : user.email.split('@').first;
              await ref.read(agendaUserProvider.notifier).saveGoogleRegistration(
                    nombre: nombre,
                    email: user.email,
                  );
            }
            if (context.mounted) context.go('/agenda/business-register');
          });
          return const Scaffold(
            backgroundColor: Color(0xFFFBFAF7),
            body: AgendaLoadingView(),
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

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          final authUser = ref.read(authStateProvider).user;
          if (authUser != null && authUser.email.isNotEmpty) {
            final trimmedName = authUser.name?.trim();
            final nombre = (trimmedName != null && trimmedName.isNotEmpty)
                ? trimmedName
                : authUser.email.split('@').first;
            await ref.read(agendaUserProvider.notifier).saveGoogleRegistration(
                  nombre: nombre,
                  email: authUser.email,
                );
          }
          if (!context.mounted) return;
          if (bizState.items.isNotEmpty) {
            context.go('/agenda/businesses/${bizState.items.first.id}');
          } else {
            context.go('/agenda/business-register');
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
