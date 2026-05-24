import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../../../../providers/agenda/tenant/horarios_controller_provider.dart';

const _kDayAbbr = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _kDayFull = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
];

class DayRow extends StatelessWidget {
  const DayRow({
    super.key,
    required this.day,
    required this.onToggle,
    required this.onPickFrom1,
    required this.onPickTo1,
    required this.onPickFrom2,
    required this.onPickTo2,
    required this.onAddBreak,
    required this.onRemoveBreak,
    required this.onCopy,
  });

  final DayDraft day;
  final VoidCallback onToggle;
  final VoidCallback onPickFrom1;
  final VoidCallback onPickTo1;
  final VoidCallback onPickFrom2;
  final VoidCallback onPickTo2;
  final VoidCallback onAddBreak;
  final VoidCallback onRemoveBreak;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final fullName = _kDayFull[day.diaSemana];
    final abbr = _kDayAbbr[day.diaSemana];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Custom pill toggle
          _DayToggle(value: day.open, onChanged: (_) => onToggle()),
          const SizedBox(width: 12),
          // Full name + abbreviation
          SizedBox(
            width: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: day.open ? KTokens.ink : KTokens.inkSoft,
                  ),
                ),
                Text(
                  abbr.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    letterSpacing: 0.8,
                    color: KTokens.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Time chips or CERRADO
          Expanded(
            child: day.open
                ? _OpenRow(
                    day: day,
                    onPickFrom1: onPickFrom1,
                    onPickTo1: onPickTo1,
                    onPickFrom2: onPickFrom2,
                    onPickTo2: onPickTo2,
                    onAddBreak: onAddBreak,
                    onRemoveBreak: onRemoveBreak,
                  )
                : Opacity(
                    opacity: 0.55,
                    child: Text(
                      'CERRADO',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: KTokens.ink,
                      ),
                    ),
                  ),
          ),
          // Copy icon
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.drag_handle, size: 16),
            color: KTokens.inkSoft,
            tooltip: 'Copiar ${_kDayFull[day.diaSemana]}',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ─── Custom pill toggle ───────────────────────────────────────────────────────

class _DayToggle extends StatelessWidget {
  const _DayToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 20,
        decoration: BoxDecoration(
          color: value ? KTokens.accent : const Color(0xFFD8D6D0),
          borderRadius: BorderRadius.circular(KTokens.rPill),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Open row (time chips + pausa) ───────────────────────────────────────────

class _OpenRow extends StatelessWidget {
  const _OpenRow({
    required this.day,
    required this.onPickFrom1,
    required this.onPickTo1,
    required this.onPickFrom2,
    required this.onPickTo2,
    required this.onAddBreak,
    required this.onRemoveBreak,
  });

  final DayDraft day;
  final VoidCallback onPickFrom1;
  final VoidCallback onPickTo1;
  final VoidCallback onPickFrom2;
  final VoidCallback onPickTo2;
  final VoidCallback onAddBreak;
  final VoidCallback onRemoveBreak;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _TimeChip(label: _fmt(day.from1), onTap: onPickFrom1),
        _Arrow(),
        _TimeChip(label: _fmt(day.to1), onTap: onPickTo1),
        if (!day.hasBreak)
          _DashedChip(label: '+ pausa', onTap: onAddBreak)
        else ...[
          _DashedLabel(),
          _TimeChip(label: _fmt(day.from2), onTap: onPickFrom2),
          _Arrow(),
          _TimeChip(label: _fmt(day.to2), onTap: onPickTo2),
          _RemovePausaBtn(onRemove: onRemoveBreak),
        ],
      ],
    );
  }
}

// ─── Time chip ────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: KTokens.surface,
          borderRadius: BorderRadius.circular(KTokens.rSm),
          border: Border.all(color: KTokens.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: KTokens.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Arrow ────────────────────────────────────────────────────────────────────

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '→',
      style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkSoft),
    );
  }
}

// ─── Dashed chip (+ pausa button) ────────────────────────────────────────────

class _DashedChip extends StatelessWidget {
  const _DashedChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(KTokens.rSm),
          border: Border.all(color: KTokens.inkPlaceholder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: KTokens.inkSoft),
        ),
      ),
    );
  }
}

// ─── Dashed label (separator between two ranges) ─────────────────────────────

class _DashedLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '· pausa ·',
      style: GoogleFonts.inter(
        fontSize: 11,
        color: KTokens.inkMuted,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

// ─── Remove pausa button ──────────────────────────────────────────────────────

class _RemovePausaBtn extends StatelessWidget {
  const _RemovePausaBtn({required this.onRemove});
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: Text(
        '× pausa',
        style: GoogleFonts.inter(
          fontSize: 11,
          color: KTokens.inkSoft,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
