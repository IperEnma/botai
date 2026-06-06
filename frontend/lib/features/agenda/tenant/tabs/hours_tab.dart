import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/agenda/agenda_user_provider.dart';
import '../../../../providers/agenda/tenant/business_hours_provider.dart';
import '../../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../../providers/agenda/tenant/horarios_controller_provider.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';
import '../../register/konecta_tokens.dart';
import '../../shared/k_mobile_top_bar.dart';
import '../widgets/agenda_left_nav.dart';
import 'horarios/widgets/exceptions_card.dart';
import 'horarios/widgets/page_header.dart';
import 'horarios/widgets/preview_panel.dart';
import 'horarios/widgets/schedule_card.dart';
import 'horarios/widgets/settings_card.dart';

// Preview sidebar breakpoint
const _kSidebarBreak = 1024.0;

class HoursTab extends ConsumerWidget {
  const HoursTab({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  ({String tenantId, String businessId}) get _key =>
      (tenantId: tenantId, businessId: businessId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoursState = ref.watch(businessHoursProvider(_key));

    // Show loading while backend data is fetching
    if (hoursState.isLoading) {
      return const Scaffold(
        backgroundColor: KTokens.bg,
        body: AgendaLoadingView(message: 'Cargando horarios…'),
      );
    }

    if (hoursState.error != null) {
      return Scaffold(
        backgroundColor: KTokens.bg,
        body: AgendaErrorView(
          message: hoursState.error!,
          onRetry: () =>
              ref.read(businessHoursProvider(_key).notifier).load(),
        ),
      );
    }

    return _HorariosLayout(tenantId: tenantId, businessId: businessId);
  }
}

class _HorariosLayout extends ConsumerWidget {
  const _HorariosLayout({
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  ({String tenantId, String businessId}) get _key =>
      (tenantId: tenantId, businessId: businessId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(horariosControllerProvider(_key));
    final notifier = ref.read(horariosControllerProvider(_key).notifier);

    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= _kSidebarBreak;
    final isMobile = !showSidebar;

    // Mobile drawer data
    final nombre = isMobile
        ? ref.watch(agendaUserProvider).valueOrNull?.nombre
        : null;
    final businessName = isMobile
        ? ref
            .watch(businessesProvider(tenantId))
            .items
            .where((b) => b.id == businessId)
            .firstOrNull
            ?.nombre
        : null;

    // Handle save result via snackbar
    ref.listen<HorariosState>(horariosControllerProvider(_key), (prev, next) {
      if (prev != null && prev.isSaving && !next.isSaving) {
        final ok = next.error == null;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            ok ? 'Horarios guardados correctamente' : 'Error: ${next.error}',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: ok ? KTokens.excOpen : KTokens.excClosed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KTokens.rSm),
          ),
        ));
      }
    });

    final scrollView = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: HorariosPageHeader(
            hasChanges: state.hasChanges,
            isSaving: state.isSaving,
            onSave: () => notifier.save(),
            onRevert: notifier.revert,
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: showSidebar
                ? _WideLayout(
                    tenantId: tenantId,
                    businessId: businessId,
                  )
                : _NarrowLayout(
                    tenantId: tenantId,
                    businessId: businessId,
                  ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );

    return Scaffold(
      backgroundColor: KTokens.bg,
      drawer: isMobile
          ? Drawer(
              width: kAgendaNavWidth,
              child: AgendaLeftNav(
                nombre: nombre,
                businessName: businessName,
                tenantId: tenantId,
                businessId: businessId,
              ),
            )
          : null,
      body: isMobile
          ? Column(
              children: [
                const KMobileTopBar(),
                Expanded(child: scrollView),
              ],
            )
          : scrollView,
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content column
        Expanded(
          child: Column(
            children: [
              ScheduleCard(
                tenantId: tenantId,
                businessId: businessId,
              ),
              const SizedBox(height: 16),
              SettingsCard(
                tenantId: tenantId,
                businessId: businessId,
              ),
              const SizedBox(height: 16),
              ExceptionsCard(
                tenantId: tenantId,
                businessId: businessId,
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Sticky sidebar
        StickyPreviewPanel(
          tenantId: tenantId,
          businessId: businessId,
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScheduleCard(
          tenantId: tenantId,
          businessId: businessId,
        ),
        const SizedBox(height: 16),
        SettingsCard(
          tenantId: tenantId,
          businessId: businessId,
        ),
        const SizedBox(height: 16),
        ExceptionsCard(
          tenantId: tenantId,
          businessId: businessId,
        ),
        const SizedBox(height: 16),
        PreviewPanel(
          tenantId: tenantId,
          businessId: businessId,
        ),
      ],
    );
  }
}

/// Sticky wrapper for the preview panel (desktop only).
class StickyPreviewPanel extends StatelessWidget {
  const StickyPreviewPanel({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: PreviewPanel(
        tenantId: tenantId,
        businessId: businessId,
      ),
    );
  }
}
