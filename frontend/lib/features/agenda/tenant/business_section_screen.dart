import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import '../../../providers/agenda/tenant_admin_resolved_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../navigation/agenda_tenant_nav.dart';
import '../theme/agenda_tokens.dart';
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

    final async = ref.watch(tenantAdminResolvedProvider);

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFFBFAF7),
        body: AgendaLoadingView(),
      ),
      error: (e, _) {
        if (e is TenantAdminResolveException && e.code == 'NOT_AUTHENTICATED') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
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
        child: _SectionView(
          tenantId:   ctx.tenantId,
          businessId: businessId,
          section:    section,
        ),
      ),
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

  AppBar _appBar(String title) => AppBar(
    backgroundColor: AgendaTokens.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    title: Text(title, style: AgendaTokens.appBarTitle),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= _kSectionBreak;
    final title = BusinessSectionScreen.titleFor(section);

    // Data for the nav
    final nombre = ref.watch(agendaUserProvider).valueOrNull?.nombre;
    final businessesState = ref.watch(businessesProvider(tenantId));
    final businessName =
        businessesState.items.where((b) => b.id == businessId).firstOrNull?.nombre;

    Widget content;

    // StylesTab needs the full Business object
    if (section == 'styles') {
      if (businessesState.isLoading) {
        content = Scaffold(
          appBar: isWide ? null : _appBar(title),
          body: const AgendaLoadingView(),
        );
      } else if (businessesState.error != null) {
        content = Scaffold(
          appBar: isWide ? null : _appBar(title),
          body: AgendaErrorView(
            message: businessesState.error!,
            onRetry: () =>
                ref.read(businessesProvider(tenantId).notifier).load(),
          ),
        );
      } else {
        final business =
            businessesState.items.where((b) => b.id == businessId).firstOrNull;
        if (business == null) {
          content = Scaffold(
            appBar: isWide ? null : _appBar(title),
            body: const AgendaEmptyState(
              icon: Icons.store_mall_directory_outlined,
              title: 'Negocio no encontrado',
              subtitle: 'Es posible que haya sido eliminado.',
            ),
          );
        } else {
          content = Scaffold(
            backgroundColor: AgendaTokens.surface,
            appBar: isWide ? null : _appBar(title),
            body: StylesTab(tenantId: tenantId, business: business),
          );
        }
      }
    } else if (section == 'hours') {
      // HoursTab manages its own header — no AppBar wrapper needed
      content = HoursTab(tenantId: tenantId, businessId: businessId);
    } else {
      final body = switch (section) {
        'services' => ServicesTab(tenantId: tenantId, businessId: businessId),
        'plans'    => PlansTab(tenantId: tenantId, businessId: businessId),
        'staff'    => StaffTab(tenantId: tenantId, businessId: businessId),
        _          => const Center(child: Text('Sección no encontrada')),
      };
      content = Scaffold(
        backgroundColor: AgendaTokens.surface,
        body: body,
      );
    }

    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBFAF7),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AgendaLeftNav(
              nombre:       nombre,
              businessName: businessName,
              tenantId:     tenantId,
              businessId:   businessId,
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return content;
  }
}
