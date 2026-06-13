import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import '../../../providers/agenda/me_profile_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../navigation/agenda_tenant_nav.dart';
import '../shared/k_mobile_top_bar.dart';
import '../theme/agenda_tokens.dart';
import 'tabs/clientes_tab.dart';
import 'tabs/hours_tab.dart';
import 'tabs/plans_tab.dart';
import 'tabs/services_tab.dart';
import 'tabs/staff_tab.dart';
import 'tabs/styles_tab.dart';
import 'widgets/agenda_left_nav.dart';

class BusinessSectionScreen extends ConsumerWidget {
  const BusinessSectionScreen({
    super.key,
    required this.businessId,
    required this.section,
  });

  final String businessId;
  final String section;

  static String titleFor(String section) => switch (section) {
    'hours'    => 'Horarios',
    'styles'   => 'Estilos',
    'services' => 'Servicios',
    'plans'    => 'Planes',
    'staff'    => 'Equipo',
    'clientes' => 'Clientes',
    _          => section,
  };

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
        // Sin tenant: el usuario aún no terminó onboarding (caso owner nuevo).
        // El panel principal arma el flow de business-register; acá nos
        // limitamos a devolverlo al panel para que lo maneje.
        if (profile.tenantId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/agenda/panel');
          });
          return const Scaffold(body: AgendaLoadingView());
        }
        return TenantNavScope(
          useMeRoutes: true,
          child: _SectionView(
            tenantId:   profile.tenantId!,
            businessId: businessId,
            section:    section,
          ),
        );
      },
    );
  }
}

const _kSectionBreak = 1024.0;

// ── Section body ──────────────────────────────────────────────────────────────

class _SectionView extends ConsumerWidget {
  const _SectionView({
    required this.tenantId,
    required this.businessId,
    required this.section,
  });

  final String tenantId;
  final String businessId;
  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= _kSectionBreak;

    final nombre = ref.watch(agendaUserProvider).valueOrNull?.nombre;
    final businessesState = ref.watch(businessesProvider(tenantId));
    final businessName =
        businessesState.items.where((b) => b.id == businessId).firstOrNull?.nombre;

    final leftNav = AgendaLeftNav(
      nombre:       nombre,
      businessName: businessName,
      tenantId:     tenantId,
      businessId:   businessId,
    );

    // ── Wide: existing nested-scaffold layout ─────────────────────────────────
    if (isWide) {
      Widget content;
      if (section == 'styles') {
        if (businessesState.isLoading) {
          content = const Scaffold(body: AgendaLoadingView());
        } else if (businessesState.error != null) {
          content = Scaffold(
            body: AgendaErrorView(
              message: businessesState.error!,
              onRetry: () =>
                  ref.read(businessesProvider(tenantId).notifier).load(),
            ),
          );
        } else {
          final business = businessesState.items
              .where((b) => b.id == businessId)
              .firstOrNull;
          content = business == null
              ? const Scaffold(
                  body: AgendaEmptyState(
                    icon: Icons.store_mall_directory_outlined,
                    title: 'Negocio no encontrado',
                    subtitle: 'Es posible que haya sido eliminado.',
                  ),
                )
              : Scaffold(
                  backgroundColor: AgendaTokens.surface,
                  body: StylesTab(tenantId: tenantId, business: business),
                );
        }
      } else if (section == 'hours') {
        content = HoursTab(tenantId: tenantId, businessId: businessId);
      } else if (section == 'clientes') {
        content = Scaffold(
          backgroundColor: AgendaTokens.surface,
          body: ClientesTab(businessId: businessId),
        );
      } else {
        final body = switch (section) {
          'services' => ServicesTab(tenantId: tenantId, businessId: businessId),
          'plans'    => PlansTab(tenantId: tenantId, businessId: businessId),
          'staff'    => StaffTab(tenantId: tenantId, businessId: businessId),
          _          => const Center(child: Text('Sección no encontrada')),
        };
        content = Scaffold(backgroundColor: AgendaTokens.surface, body: body);
      }

      return Scaffold(
        backgroundColor: const Color(0xFFFBFAF7),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            leftNav,
            Expanded(child: content),
          ],
        ),
      );
    }

    // ── Mobile ────────────────────────────────────────────────────────────────
    // HoursTab manages its own Scaffold + drawer + hamburger internally.
    if (section == 'hours') {
      return HoursTab(tenantId: tenantId, businessId: businessId);
    }

    // All other sections: single Scaffold with drawer + AppBar hamburger.
    Widget body;
    if (section == 'styles') {
      if (businessesState.isLoading) {
        body = const AgendaLoadingView();
      } else if (businessesState.error != null) {
        body = AgendaErrorView(
          message: businessesState.error!,
          onRetry: () =>
              ref.read(businessesProvider(tenantId).notifier).load(),
        );
      } else {
        final business = businessesState.items
            .where((b) => b.id == businessId)
            .firstOrNull;
        body = business == null
            ? const AgendaEmptyState(
                icon: Icons.store_mall_directory_outlined,
                title: 'Negocio no encontrado',
                subtitle: 'Es posible que haya sido eliminado.',
              )
            : StylesTab(tenantId: tenantId, business: business);
      }
    } else {
      body = switch (section) {
        'clientes' => ClientesTab(businessId: businessId),
        'services' => ServicesTab(tenantId: tenantId, businessId: businessId),
        'plans'    => PlansTab(tenantId: tenantId, businessId: businessId),
        'staff'    => StaffTab(tenantId: tenantId, businessId: businessId),
        _          => const Center(child: Text('Sección no encontrada')),
      };
    }

    return Scaffold(
      backgroundColor: AgendaTokens.surface,
      drawer: Drawer(width: kAgendaNavWidth, child: leftNav),
      body: Column(
        children: [
          const KMobileTopBar(),
          Expanded(child: body),
        ],
      ),
    );
  }
}
