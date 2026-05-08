import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import '../../../providers/agenda/tenant_admin_resolved_provider.dart';
import '../../../services/agenda_api_exception.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
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
          // Primera vez con Google: no hay cuenta Agenda todavía → ir directo al onboarding
          // (mismo flujo que WhatsApp). Evitamos mostrar una pantalla técnica intermedia.
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!context.mounted) return;
            final auth = ref.read(authStateProvider);
            final user = auth.user;
            final email = user?.email.trim() ?? '';
            if (!auth.isAuthenticated || user == null || email.isEmpty) {
              context.go('/login');
              return;
            }
            final trimmedName = user.name?.trim();
            final nombre = (trimmedName != null && trimmedName.isNotEmpty)
                ? trimmedName
                : email.split('@').first;
            await ref.read(agendaUserProvider.notifier).saveGoogleRegistration(
                  nombre: nombre,
                  email: email,
                );
            if (!context.mounted) return;
            context.go('/agenda/intent');
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
      data: (ctx) => TenantNavScope(
        useMeRoutes: true,
        child: TenantHomeScreen(tenantId: ctx.tenantId),
      ),
    );
  }
}
