import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import '../../../providers/agenda/me_profile_provider.dart';
import '../../../providers/agenda/selected_agenda_business_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../navigation/agenda_tenant_nav.dart';
import 'tenant_home_screen.dart';

/// Panel admin Agenda en `/agenda/panel`. Tenant por login; sucursal en [selectedAgendaBusinessIdProvider].
class AgendaPanelScreen extends ConsumerWidget {
  const AgendaPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(body: AgendaLoadingView());
    }

    final async = ref.watch(meProfileProvider);

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFFBFAF7),
        body: AgendaLoadingView(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFFBFAF7),
        body: AgendaErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(meProfileProvider),
        ),
      ),
      data: (profile) {
        // Sin tenant resuelto: usuario autenticado en Google pero todavía sin
        // cuenta Agenda (caso owner nuevo). Pre-llenar registro con sus datos
        // de Google y mandarlo al alta de negocio.
        if (profile.tenantId == null) {
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
            if (context.mounted) context.go('/agenda/business-register');
          });
          return const Scaffold(
            backgroundColor: Color(0xFFFBFAF7),
            body: AgendaLoadingView(),
          );
        }
        final tenantId = profile.tenantId!;
        final bizState = ref.watch(businessesProvider(tenantId));

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
                  ref.read(businessesProvider(tenantId).notifier).load(),
            ),
          );
        }

        if (bizState.items.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/agenda/business-register');
          });
          return const Scaffold(
            backgroundColor: Color(0xFFFBFAF7),
            body: AgendaLoadingView(),
          );
        }

        var selectedId = ref.watch(selectedAgendaBusinessIdProvider);
        final ids = bizState.items.map((b) => b.id).toSet();
        // STAFF: forzar la sucursal seleccionada a una donde tenga rol.
        if (profile.isStaffOnly) {
          final allowed = profile.staffBusinessIds.intersection(ids);
          if (allowed.isNotEmpty &&
              (selectedId == null || !allowed.contains(selectedId))) {
            selectedId = allowed.first;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedAgendaBusinessIdProvider.notifier).state =
                  selectedId;
            });
          }
        }
        if (selectedId == null || !ids.contains(selectedId)) {
          selectedId = bizState.items.first.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedAgendaBusinessIdProvider.notifier).state =
                selectedId;
          });
        }

        // STAFF puro: el "Inicio" del panel no tiene sentido — saltarlo a la
        // sección Agenda directamente.
        final currentSection = GoRouterState.of(context)
                .uri
                .queryParameters['section'] ??
            '';
        if (profile.isStaffOnly && currentSection != 'agenda') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/agenda/panel?section=agenda');
          });
          return const Scaffold(
            backgroundColor: Color(0xFFFBFAF7),
            body: AgendaLoadingView(),
          );
        }

        return TenantNavScope(
          useMeRoutes: true,
          child: TenantHomeScreen(
            tenantId: tenantId,
            businessId: selectedId,
          ),
        );
      },
    );
  }
}
