import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../controllers/servicios_controller.dart';
import '../modals/change_category_modal.dart';
import '../panels/add_service_panel.dart';
import '../panels/service_detail_panel.dart';
import '../widgets/category_bar.dart';
import '../widgets/service_group_card.dart';
import '../widgets/servicios_page_header.dart';
import '../widgets/servicios_toolbar.dart';

class ServiciosScreen extends ConsumerWidget {
  const ServiciosScreen({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  ServiciosKey get _key => (tenantId: tenantId, businessId: businessId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviciosProvider(_key));
    final notifier = ref.read(serviciosProvider(_key).notifier);

    if (state.isLoading) {
      return const ColoredBox(
        color: KTokens.bg,
        child: AgendaLoadingView(message: 'Cargando servicios…'),
      );
    }

    if (state.error != null) {
      return ColoredBox(
        color: KTokens.bg,
        child: AgendaErrorView(
          message: state.error!,
          onRetry: () => notifier.reload(),
        ),
      );
    }

    final items = notifier.visibleItems;

    final isNarrow = MediaQuery.sizeOf(context).width < 700;

    return Container(
      color: KTokens.bg,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(isNarrow ? 20 : 32, 28, isNarrow ? 20 : 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ServiciosPageHeader(
              onAdd: () => showAddServicePanel(context, _key),
              onImport: () {},
            ),
            const SizedBox(height: 20),
            CategoryBar(
              categories: state.categories,
              onChangeCategory: () => showChangeCategoryModal(context, _key),
            ),
            const SizedBox(height: 20),
            ServiciosToolbar(state: state, notifier: notifier),
            const SizedBox(height: 20),

            if (items.isEmpty)
              _EmptyState(filter: state.filter)
            else
              ServiciosCard(
                services: items,
                allStaff: state.staff,
                staffForService: notifier.staffForService,
                onTapService: (s) => showServiceDetailPanel(context, _key, s),
                onAdd: () => showAddServicePanel(context, _key),
                onToggleActive: (id) => notifier.toggleActive(id),
                onDuplicateService: (s) => notifier.duplicate(s),
                onDeleteService: (id) => notifier.remove(id),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final ServicioFilter filter;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (filter) {
      ServicioFilter.inactive => (
          Icons.pause_circle_outline,
          'Sin servicios inactivos',
          'Todos tus servicios están activos.',
        ),
      ServicioFilter.active => (
          Icons.design_services_outlined,
          'Sin servicios activos',
          'Activá un servicio o creá uno nuevo.',
        ),
      ServicioFilter.all => (
          Icons.design_services_outlined,
          'Sin servicios',
          'Agregá tu primer servicio con el botón "+ Agregar servicio".',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: KTokens.inkPlaceholder),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: KTokens.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
