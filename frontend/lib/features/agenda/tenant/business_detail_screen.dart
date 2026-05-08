import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/agenda_tokens.dart';

import '../../../models/agenda/business.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import 'tabs/hours_tab.dart';
import 'tabs/loyalty_tab.dart';
import 'tabs/plans_tab.dart';
import 'tabs/services_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/staff_tab.dart';
import 'tabs/styles_tab.dart';

class BusinessDetailScreen extends ConsumerWidget {
  const BusinessDetailScreen({
    super.key,
    required this.tenantId,
    required this.businessId,
    this.initialTabIndex = 0,
  });

  final String tenantId;
  final String businessId;
  final int    initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(businessesProvider(tenantId));

    if (state.isLoading) return const Scaffold(body: AgendaLoadingView());
    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AgendaTokens.primary, foregroundColor: Colors.white, elevation: 0, title: Text('Negocio', style: AgendaTokens.appBarTitle)),
        body: AgendaErrorView(
          message: state.error!,
          onRetry: () => ref.read(businessesProvider(tenantId).notifier).load(),
        ),
      );
    }

    final business = state.items.where((b) => b.id == businessId).firstOrNull;
    if (business == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AgendaTokens.primary, foregroundColor: Colors.white, elevation: 0, title: Text('Negocio', style: AgendaTokens.appBarTitle)),
        body: const AgendaEmptyState(
          icon: Icons.store_mall_directory_outlined,
          title: 'Negocio no encontrado',
          subtitle: 'Es posible que haya sido eliminado.',
        ),
      );
    }

    return _BusinessDetailView(
      tenantId:        tenantId,
      business:        business,
      initialTabIndex: initialTabIndex,
    );
  }
}

class _BusinessDetailView extends StatelessWidget {
  const _BusinessDetailView({
    required this.tenantId,
    required this.business,
    required this.initialTabIndex,
  });

  final String   tenantId;
  final Business business;
  final int      initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      initialIndex: initialTabIndex,
      child: Scaffold(
        backgroundColor: AgendaTokens.surface,
        appBar: AppBar(
          backgroundColor: AgendaTokens.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(business.nombre, style: AgendaTokens.appBarTitle),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: AgendaTokens.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: AgendaTokens.poppins(fontSize: 13),
            tabs: const [
              Tab(text: 'Horarios'),
              Tab(text: 'Estilos'),
              Tab(text: 'Servicios'),
              Tab(text: 'Planes'),
              Tab(text: 'Settings'),
              Tab(text: 'Loyalty'),
              Tab(text: 'Equipo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            HoursTab(tenantId: tenantId, businessId: business.id),
            StylesTab(tenantId: tenantId, business: business),
            ServicesTab(tenantId: tenantId, businessId: business.id),
            PlansTab(tenantId: tenantId, businessId: business.id),
            SettingsTab(tenantId: tenantId, businessId: business.id),
            LoyaltyTab(tenantId: tenantId, businessId: business.id),
            StaffTab(tenantId: tenantId, businessId: business.id),
          ],
        ),
      ),
    );
  }
}
