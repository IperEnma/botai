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
    final abbr = _kDayAbbr[day.diaSemana];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          // Toggle
          SizedBox(
            width: 36,
            height: 36,
            child: Transform.scale(
              scale: 0.75,
              child: Switch(
                value: day.open,
                onChanged: (_) => onToggle(),
                activeThumbColor: KTokens.accent,
                activeTrackColor: KTokens.accentSoft,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Day abbreviation (mono)
          SizedBox(
            width: 28,
            child: Text(
              abbr.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                letterSpacing: 0.8,
                color: day.open ? KTokens.ink : KTokens.inkSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Time chips or CERRADO
          Expanded(
            child: day.open ? _OpenRow(
              day: day,
              onPickFrom1: onPickFrom1,
              onPickTo1: onPickTo1,
              onPickFrom2: onPickFrom2,
              onPickTo2: onPickTo2,
              onAddBreak: onAddBreak,
              onRemoveBreak: onRemoveBreak,
            ) : Opacity(
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
            icon: const Icon(Icons.content_copy_rounded, size: 15),
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
          _DashedChip(
            label: '+ pausa',
            onTap: onAddBreak,
          )
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

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '→',
      style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkSoft),
    );
  }
}

class _DashedLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '+ pausa',
      style: GoogleFonts.inter(
        fontSize: 11,
        color: KTokens.inkMuted,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

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
          border: Border.all(
            color: KTokens.inkPlaceholder,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: KTokens.inkSoft,
          ),
        ),
      ),
    );
  }
}

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
