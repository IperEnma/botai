import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../providers/agenda/agenda_api_provider.dart';
import '../../../../providers/agenda/tenant/agenda_bookings_provider.dart';
import '../../../../providers/agenda/tenant/agenda_month_provider.dart';
import '../../../../providers/agenda/tenant/agenda_week_provider.dart';
import 'booking_draft.dart';
import 'booking_wizard_controller.dart';
import 'steps/step_cliente.dart';
import 'steps/step_fecha_hora.dart';
import 'steps/step_profesional.dart';
import 'steps/step_servicio.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showBookingWizardPanel(
  BuildContext context, {
  required String tenantId,
  required String businessId,
  DateTime? initialDate,
  String? initialProId,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim, secondary) => _BookingWizardPanel(
      tenantId: tenantId,
      businessId: businessId,
      initialDate: initialDate,
      initialProId: initialProId,
    ),
    transitionBuilder: (ctx, anim, secondary, child) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return Stack(
        children: [
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ],
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel widget
// ─────────────────────────────────────────────────────────────────────────────

class _BookingWizardPanel extends ConsumerStatefulWidget {
  const _BookingWizardPanel({
    required this.tenantId,
    required this.businessId,
    this.initialDate,
    this.initialProId,
  });

  final String tenantId;
  final String businessId;
  final DateTime? initialDate;
  final String? initialProId;

  @override
  ConsumerState<_BookingWizardPanel> createState() => _BookingWizardPanelState();
}

class _BookingWizardPanelState extends ConsumerState<_BookingWizardPanel> {
  late final BookingWizardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BookingWizardController(
      businessId: widget.businessId,
      initialDate: widget.initialDate,
      initialProId: widget.initialProId,
    );
    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  DateTime _weekStart(DateTime d) {
    final diff = d.weekday - 1; // Monday-based: weekday 1=Mon
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: diff));
  }

  void _handleConfirm() {
    final api = ref.read(agendaApiServiceProvider);
    _controller.confirm(
      api,
      () {
        if (!mounted) return;
        final d = _controller.draft;
        final date = d.date!;

        ref.invalidate(agendaWeekBookingsProvider((
          businessId: widget.businessId,
          weekStart: _weekStart(date),
        )));
        ref.invalidate(agendaBookingsProvider((
          businessId: widget.businessId,
          day: date,
        )));
        ref.invalidate(agendaMonthBookingsProvider((
          businessId: widget.businessId,
          year: date.year,
          month: date.month,
        )));

        Navigator.of(context).pop();

        final time = d.time!;
        final dayAbbrs = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
        final dayAbbr = dayAbbrs[date.weekday % 7];
        final timeStr =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        final proNombre = !d.requiresStaffStep
            ? 'agenda del negocio'
            : d.anyProfessional
                ? 'cualquier profesional'
                : (d.profesionalId ?? 'el profesional');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Turno agendado · ${d.cliente!.nombre} · $dayAbbr ${date.day} $timeStr con $proNombre',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: KTokens.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error,
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 460,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 40,
                offset: Offset(-8, 0),
              ),
            ],
          ),
          child: ProviderScope(
            child: Column(
              children: [
                // Fixed header
                _WizardHeader(
                  topPad: topPad,
                  controller: _controller,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Divider(height: 1, color: KTokens.border),
                // Crumbs
                _WizardCrumbs(
                  controller: _controller,
                ),
                // Step content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildStep(_controller.step),
                  ),
                ),
                Divider(height: 1, color: KTokens.border),
                // Fixed footer
                _WizardFooter(
                  bottomPad: bottomPad,
                  controller: _controller,
                  onConfirm: _handleConfirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BookingStep step) {
    switch (step) {
      case BookingStep.cliente:
        return StepCliente(
          key: const ValueKey('step_cliente'),
          controller: _controller,
          businessId: widget.businessId,
        );
      case BookingStep.servicio:
        return _ProviderScopeWrapper(
          key: const ValueKey('step_servicio'),
          child: StepServicio(
            controller: _controller,
            tenantId: widget.tenantId,
            businessId: widget.businessId,
          ),
        );
      case BookingStep.profesional:
        return _ProviderScopeWrapper(
          key: const ValueKey('step_profesional'),
          child: StepProfesional(
            controller: _controller,
            tenantId: widget.tenantId,
            businessId: widget.businessId,
          ),
        );
      case BookingStep.fechaHora:
        return _ProviderScopeWrapper(
          key: const ValueKey('step_fecha_hora'),
          child: StepFechaHora(
            controller: _controller,
            tenantId: widget.tenantId,
            businessId: widget.businessId,
          ),
        );
    }
  }
}

/// Wrapper to ensure Riverpod is accessible (showGeneralDialog creates new subtree)
class _ProviderScopeWrapper extends StatelessWidget {
  const _ProviderScopeWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({
    required this.topPad,
    required this.controller,
    required this.onClose,
  });

  final double topPad;
  final BookingWizardController controller;
  final VoidCallback onClose;

  int get _stepNumber {
    final steps = controller.draft.activeSteps;
    final idx = steps.indexOf(controller.step);
    return idx >= 0 ? idx + 1 : 1;
  }

  int get _totalSteps => controller.draft.activeSteps.length;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(28, topPad + 20, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NUEVA AGENDA',
                      style: KTokens.tEyebrow
                          .copyWith(fontSize: 10, letterSpacing: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agendá un cliente',
                      style: KTokens.tHero.copyWith(color: KTokens.accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Semantics(
                button: true,
                label: 'Cerrar panel',
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: KTokens.border),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: KTokens.inkSoft,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: 'Paso $_stepNumber de $_totalSteps',
            child: _ProgressSegments(controller: controller),
          ),
          const SizedBox(height: 6),
          Text(
            'PASO ${_stepNumber.toString().padLeft(2, '0')} DE ${_totalSteps.toString().padLeft(2, '0')}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: KTokens.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSegments extends StatelessWidget {
  const _ProgressSegments({required this.controller});
  final BookingWizardController controller;

  @override
  Widget build(BuildContext context) {
    final steps = controller.draft.activeSteps;
    final currentIdx = steps.indexOf(controller.step);
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i <= currentIdx;
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: active ? KTokens.accent : const Color(0x12000000),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Crumbs
// ─────────────────────────────────────────────────────────────────────────────

class _WizardCrumbs extends StatelessWidget {
  const _WizardCrumbs({required this.controller});
  final BookingWizardController controller;

  @override
  Widget build(BuildContext context) {
    final crumbs = _buildCrumbs();
    if (crumbs.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: KTokens.bg,
        border: Border(bottom: BorderSide(color: KTokens.border)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: crumbs,
      ),
    );
  }

  List<Widget> _buildCrumbs() {
    final step = controller.step;
    final draft = controller.draft;
    final crumbs = <Widget>[];

    // Step >= servicio: show cliente
    if (BookingStep.values.indexOf(step) >= 1 && draft.cliente != null) {
      crumbs.add(_Crumb(
        label: draft.cliente!.nombre,
        onTap: () => controller.goTo(BookingStep.cliente),
        semanticLabel: 'Editar cliente',
      ));
    }

    // Step >= servicio completado: mostrar servicio
    if (draft.activeSteps.indexOf(step) >= 1 && draft.servicio != null) {
      final svc = draft.servicio!;
      crumbs.add(_Crumb(
        label: '${svc.nombre} · ${svc.duracionMin}m',
        onTap: () => controller.goTo(BookingStep.servicio),
        semanticLabel: 'Editar servicio',
      ));
    }

    // Paso fecha/hora con agenda por profesional: mostrar profesional
    if (step == BookingStep.fechaHora && draft.requiresStaffStep) {
      final proLabel = draft.anyProfessional
          ? 'Cualquiera'
          : (draft.profesionalId != null ? 'Profesional' : null);
      if (proLabel != null) {
        crumbs.add(_Crumb(
          label: proLabel,
          onTap: () => controller.goTo(BookingStep.profesional),
          semanticLabel: 'Editar profesional',
        ));
      }
    }

    return crumbs;
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.label,
    required this.onTap,
    required this.semanticLabel,
  });

  final String label;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: KTokens.accentSoft,
            borderRadius: BorderRadius.circular(KTokens.rPill),
            border: Border.all(
              color: KTokens.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: KTokens.accent,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: KTokens.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────

class _WizardFooter extends StatelessWidget {
  const _WizardFooter({
    required this.bottomPad,
    required this.controller,
    required this.onConfirm,
  });

  final double bottomPad;
  final BookingWizardController controller;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final canAdvance = controller.canAdvance;
    final isLastStep = controller.isLastStep;
    final isSubmitting = controller.isSubmitting;
    final isFirst = controller.step == BookingStep.cliente;

    final btnLabel =
        isLastStep ? 'Confirmar agenda →' : 'Continuar →';
    final btnBg = canAdvance ? KTokens.accent : const Color(0x1A000000);
    final btnFg = canAdvance ? Colors.white : KTokens.inkSoft;

    return Container(
      padding: EdgeInsets.fromLTRB(28, 16, 28, 16 + bottomPad),
      child: Row(
        children: [
          if (!isFirst)
            OutlinedButton(
              onPressed: isSubmitting ? null : controller.back,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                side: BorderSide(color: KTokens.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KTokens.rMd),
                ),
              ),
              child: Text(
                '← Atrás',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: KTokens.inkMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const Spacer(),
          Semantics(
            enabled: canAdvance,
            label: btnLabel,
            child: ElevatedButton(
              onPressed:
                  (canAdvance && !isSubmitting)
                      ? (isLastStep ? onConfirm : controller.next)
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnBg,
                foregroundColor: btnFg,
                disabledBackgroundColor: const Color(0x1A000000),
                disabledForegroundColor: KTokens.inkSoft,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KTokens.rMd),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      btnLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: btnFg,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
