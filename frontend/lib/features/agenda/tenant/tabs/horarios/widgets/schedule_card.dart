import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../../../../providers/agenda/tenant/horarios_controller_provider.dart';
import 'day_row.dart';

const _kDayFull = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
];
const _kDayAbbr = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

class ScheduleCard extends ConsumerStatefulWidget {
  const ScheduleCard({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  ConsumerState<ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends ConsumerState<ScheduleCard> {
  int? _copySourceDay;

  ({String tenantId, String businessId}) get _key =>
      (tenantId: widget.tenantId, businessId: widget.businessId);

  Future<void> _pickTime(
    BuildContext context,
    DayDraft day,
    bool isFrom,
    bool isBreak,
  ) async {
    final notifier = ref.read(horariosControllerProvider(_key).notifier);
    TimeOfDay current;
    if (!isBreak) {
      current = isFrom ? day.from1 : day.to1;
    } else {
      current = isFrom ? day.from2 : day.to2;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;

    // Read the latest day state (not the closure-captured one)
    final latestDay = ref
        .read(horariosControllerProvider(_key))
        .days
        .firstWhere((d) => d.diaSemana == day.diaSemana);

    if (!isBreak) {
      if (isFrom) {
        notifier.updateFrom1(day.diaSemana, picked);
      } else {
        // to1 cannot exceed from2 when a break exists
        if (latestDay.hasBreak && _toMin(picked) > _toMin(latestDay.from2)) {
          if (context.mounted) _showBreakError(context, 'El fin del primer turno no puede ser posterior al inicio de la pausa (${_fmt(latestDay.from2)}).');
          return;
        }
        notifier.updateTo1(day.diaSemana, picked);
      }
    } else {
      if (isFrom) {
        // from2 must be >= to1
        if (_toMin(picked) < _toMin(latestDay.to1)) {
          if (context.mounted) _showBreakError(context, 'El inicio después de la pausa debe ser posterior al fin del primer turno (${_fmt(latestDay.to1)}).');
          return;
        }
        notifier.updateFrom2(day.diaSemana, picked);
      } else {
        notifier.updateTo2(day.diaSemana, picked);
      }
    }
  }

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _showBreakError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
      backgroundColor: KTokens.excClosed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KTokens.rSm)),
    ));
  }

  void _showCopyOptions(BuildContext context, int sourceDia) {
    setState(() => _copySourceDay = sourceDia);
  }

  void _copyTo(List<int> targets) {
    if (_copySourceDay == null) return;
    ref
        .read(horariosControllerProvider(_key).notifier)
        .copyDayTo(_copySourceDay!, targets);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(horariosControllerProvider(_key));
    final days = state.days;
    final srcDay = _copySourceDay != null
        ? days.firstWhere((d) => d.diaSemana == _copySourceDay,
            orElse: () => days[0])
        : null;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Builder(builder: (context) {
            final isMobile = MediaQuery.sizeOf(context).width < 700;
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horario regular',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: KTokens.ink,
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Cuándo el negocio acepta turnos cada semana.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: KTokens.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isMobile)
                  Text(
                    'UY · ZONA AMERICA/MONTEVIDEO',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: KTokens.inkSoft,
                      letterSpacing: 0.6,
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 16),
          const Divider(height: 1, color: KTokens.border),
          const SizedBox(height: 8),
          // Day rows
          ...days.map((day) => DayRow(
                day: day,
                onToggle: () => ref
                    .read(horariosControllerProvider(_key).notifier)
                    .toggleDay(day.diaSemana),
                onPickFrom1: () => _pickTime(context, day, true, false),
                onPickTo1: () => _pickTime(context, day, false, false),
                onPickFrom2: () => _pickTime(context, day, true, true),
                onPickTo2: () => _pickTime(context, day, false, true),
                onAddBreak: () => ref
                    .read(horariosControllerProvider(_key).notifier)
                    .addBreak(day.diaSemana),
                onRemoveBreak: () => ref
                    .read(horariosControllerProvider(_key).notifier)
                    .removeBreak(day.diaSemana),
                onCopy: () => _showCopyOptions(context, day.diaSemana),
              )),
          // Copy footer (desktop only)
          if (srcDay != null && MediaQuery.sizeOf(context).width >= 700) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: KTokens.border),
            const SizedBox(height: 10),
            _CopyFooter(
              sourceDia: _copySourceDay!,
              sourceDayName: _kDayFull[_copySourceDay!],
              onCopyTo: (targets) {
                _copyTo(targets);
                setState(() => _copySourceDay = null);
              },
              onDismiss: () => setState(() => _copySourceDay = null),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyFooter extends StatelessWidget {
  const _CopyFooter({
    required this.sourceDia,
    required this.sourceDayName,
    required this.onCopyTo,
    required this.onDismiss,
  });

  final int sourceDia;
  final String sourceDayName;
  final void Function(List<int>) onCopyTo;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    // laborales = 0-4 (Lun-Vie)
    final otherDays = List.generate(7, (i) => i)
        .where((i) => i != sourceDia)
        .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Copiar $sourceDayName a:',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: KTokens.inkMuted,
          ),
        ),
        ...otherDays.map((i) => _CopyChip(
              label: _kDayAbbr[i],
              onTap: () => onCopyTo([i]),
            )),
        _CopyChip(
          label: 'Días laborales',
          onTap: () => onCopyTo(
            [0, 1, 2, 3, 4].where((i) => i != sourceDia).toList(),
          ),
        ),
        _CopyChip(
          label: 'Toda la semana',
          onTap: () => onCopyTo(otherDays),
        ),
        GestureDetector(
          onTap: onDismiss,
          child: Text(
            '✕',
            style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkSoft),
          ),
        ),
      ],
    );
  }
}

class _CopyChip extends StatelessWidget {
  const _CopyChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: KTokens.accentSoft,
          borderRadius: BorderRadius.circular(KTokens.rPill),
          border: Border.all(color: KTokens.accent.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: KTokens.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KTokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}
