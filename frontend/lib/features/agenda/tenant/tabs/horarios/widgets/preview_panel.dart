import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../../../../providers/agenda/tenant/horarios_controller_provider.dart';
import '../utils/slot_generator.dart';

const _kDayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const _kDayFull = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
];

class PreviewPanel extends ConsumerStatefulWidget {
  const PreviewPanel({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  ConsumerState<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends ConsumerState<PreviewPanel> {
  late int _selectedDia;

  @override
  void initState() {
    super.initState();
    _selectedDia = (DateTime.now().weekday - 1).clamp(0, 6);
  }

  ({String tenantId, String businessId}) get _key =>
      (tenantId: widget.tenantId, businessId: widget.businessId);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(horariosControllerProvider(_key));
    final days = state.days;
    if (days.isEmpty) return const SizedBox.shrink();

    final selectedDay = days.firstWhere(
      (d) => d.diaSemana == _selectedDia,
      orElse: () => days[0],
    );
    final rules = state.rules;
    final slotsResult = generateSlots(day: selectedDay, rules: rules);

    final now = DateTime.now();
    final todayWd = now.weekday - 1;
    final diff = (_selectedDia - todayWd + 7) % 7;
    final previewDate = now.add(Duration(days: diff));

    return Container(
      width: 340,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VISTA PREVIA',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    letterSpacing: 1.4,
                    color: KTokens.inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Como lo ve tu cliente',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: KTokens.ink,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: KTokens.border),
          // Day picker
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: _DayPicker(
              days: days,
              selectedDia: _selectedDia,
              previewDate: previewDate,
              onSelect: (i) => setState(() => _selectedDia = i),
            ),
          ),
          const Divider(height: 1, color: KTokens.border),
          // Slots or closed message
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: selectedDay.open && slotsResult.all.isNotEmpty
                ? _SlotsSection(
                    result: slotsResult,
                    day: selectedDay,
                    previewDate: previewDate,
                    selectedDia: _selectedDia,
                  )
                : _ClosedMsg(dayName: _kDayFull[_selectedDia]),
          ),
          // Footer count
          if (selectedDay.open && slotsResult.all.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: KTokens.bg,
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${slotsResult.all.length}',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: KTokens.ink,
                          ),
                        ),
                        TextSpan(
                          text: ' SLOTS DISPONIBLES',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: KTokens.inkSoft,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (diff == 0)
                    Text(
                      'HOY',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: KTokens.excOpen,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Day picker ───────────────────────────────────────────────────────────────

class _DayPicker extends StatelessWidget {
  const _DayPicker({
    required this.days,
    required this.selectedDia,
    required this.previewDate,
    required this.onSelect,
  });

  final List<DayDraft> days;
  final int selectedDia;
  final DateTime previewDate;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) {
        final now = DateTime.now();
        final todayWd = now.weekday - 1;
        final diff = (d.diaSemana - todayWd + 7) % 7;
        final date = now.add(Duration(days: diff));
        final isSelected = d.diaSemana == selectedDia;

        return GestureDetector(
          onTap: () => onSelect(d.diaSemana),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? KTokens.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _kDayLetters[d.diaSemana],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isSelected
                        ? Colors.white
                        : KTokens.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : d.open
                            ? KTokens.ink
                            : KTokens.inkPlaceholder,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Slots section ────────────────────────────────────────────────────────────

class _SlotsSection extends StatelessWidget {
  const _SlotsSection({
    required this.result,
    required this.day,
    required this.previewDate,
    required this.selectedDia,
  });

  final SlotsResult result;
  final DayDraft day;
  final DateTime previewDate;
  final int selectedDia;

  @override
  Widget build(BuildContext context) {
    final dayName = _kDayFull[selectedDia].toUpperCase();
    final dayNum = previewDate.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.range1.isNotEmpty) ...[
          _SlotSectionHeader(
            left: '$dayName $dayNum · MAÑANA',
            right: 'Servicio: Corte (30m)',
          ),
          const SizedBox(height: 8),
          _SlotsGrid(slots: result.range1),
        ],
        if (result.range2.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SlotSectionHeader(
            left: 'TARDE',
            right:
                '${day.to1.hour}–${day.from2.hour} PAUSA',
          ),
          const SizedBox(height: 8),
          _SlotsGrid(slots: result.range2),
        ],
      ],
    );
  }
}

// ─── Section header row ───────────────────────────────────────────────────────

class _SlotSectionHeader extends StatelessWidget {
  const _SlotSectionHeader({required this.left, required this.right});
  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          left,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: KTokens.inkMuted,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Text(
          right,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: KTokens.inkMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── Slots grid (4 columns) ───────────────────────────────────────────────────

class _SlotsGrid extends StatelessWidget {
  const _SlotsGrid({required this.slots});
  final List<SlotPreview> slots;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    const cols = 4;
    final rows = <List<SlotPreview?>>[];
    for (var i = 0; i < slots.length; i += cols) {
      final row = <SlotPreview?>[];
      for (var j = i; j < i + cols; j++) {
        row.add(j < slots.length ? slots[j] : null);
      }
      rows.add(row);
    }

    return Column(
      children: rows.asMap().entries.map((rowEntry) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: rowEntry.key < rows.length - 1 ? 4 : 0),
          child: Row(
            children: rowEntry.value.asMap().entries.map((cellEntry) {
              final s = cellEntry.value;
              final isLast = cellEntry.key == cols - 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 4),
                  child: s != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          decoration: BoxDecoration(
                            color: s.available
                                ? KTokens.accentSoft
                                : KTokens.bg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: s.available
                                  ? KTokens.accent.withValues(alpha: 0.3)
                                  : KTokens.border,
                            ),
                          ),
                          child: Text(
                            _fmt(s.time),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: s.available
                                  ? KTokens.accent
                                  : KTokens.inkPlaceholder,
                              decoration: s.available
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Closed message ───────────────────────────────────────────────────────────

class _ClosedMsg extends StatelessWidget {
  const _ClosedMsg({required this.dayName});
  final String dayName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Icon(Icons.lock_outline,
                size: 24, color: KTokens.inkPlaceholder),
            const SizedBox(height: 6),
            Text(
              '$dayName cerrado',
              style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
