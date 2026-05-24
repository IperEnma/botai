import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../../../../providers/agenda/tenant/horarios_controller_provider.dart';

const _kMonths = [
  '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

class ExceptionRow extends StatefulWidget {
  const ExceptionRow({
    super.key,
    required this.exception,
    required this.onTap,
    required this.onDelete,
  });

  final ExceptionDraft exception;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<ExceptionRow> createState() => _ExceptionRowState();
}

class _ExceptionRowState extends State<ExceptionRow> {
  bool _hovered = false;

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  ({Color bg, Color text, String label}) _badge(ExcType t) => switch (t) {
        ExcType.closed => (
          bg: KTokens.excClosedBg,
          text: KTokens.excClosed,
          label: 'CERRADO',
        ),
        ExcType.modifiedHours => (
          bg: KTokens.excModifiedBg,
          text: KTokens.excModified,
          label: 'HORARIO',
        ),
        ExcType.vacation => (
          bg: KTokens.excClosedBg,
          text: KTokens.excClosed,
          label: 'VACACIONES',
        ),
        ExcType.openDay => (
          bg: KTokens.excOpenBg,
          text: KTokens.excOpen,
          label: 'ABIERTO',
        ),
      };

  String _metaDetail(ExceptionDraft e) {
    switch (e.type) {
      case ExcType.closed:
        return e.reason ?? 'Feriado · cerrado todo el día';
      case ExcType.modifiedHours:
        final t1 = e.from1 != null && e.to1 != null
            ? 'Hoy abrimos ${_fmtTime(e.from1!)} · ${_fmtTime(e.to1!)}'
            : 'Horario modificado';
        return t1;
      case ExcType.vacation:
        final days = e.dateTo.difference(e.dateFrom).inDays + 1;
        return 'Del ${e.dateFrom.day} al ${e.dateTo.day} de ${_kMonths[e.dateTo.month]} · $days días';
      case ExcType.openDay:
        final t1 = e.from1 != null && e.to1 != null
            ? 'Abrimos ${_fmtTime(e.from1!)} → ${_fmtTime(e.to1!)}'
            : 'Apertura excepcional';
        return t1;
    }
  }

  String _metaTitle(ExceptionDraft e) => switch (e.type) {
        ExcType.closed =>
          e.reason != null && e.reason!.isNotEmpty ? e.reason! : 'Día cerrado',
        ExcType.modifiedHours => 'Cierre temprano',
        ExcType.vacation => 'Vacaciones de invierno',
        ExcType.openDay => 'Apertura excepcional',
      };

  @override
  Widget build(BuildContext context) {
    final e = widget.exception;
    final b = _badge(e.type);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered
                ? KTokens.bg
                : Colors.transparent,
            borderRadius: BorderRadius.circular(KTokens.rSm),
          ),
          child: Row(
            children: [
              // Date box
              _DateBox(day: e.dateFrom.day, month: _kMonths[e.dateFrom.month]),
              const SizedBox(width: 16),
              // Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _metaTitle(e),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: KTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _metaDetail(e),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: KTokens.inkMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Badge
              AnimatedOpacity(
                opacity: _hovered ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: _Badge(bg: b.bg, text: b.text, label: b.label),
              ),
              // Delete icon (visible on hover)
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 120),
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: KTokens.excClosedBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: KTokens.excClosed,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.day, required this.month});
  final int day;
  final String month;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: KTokens.bg,
        borderRadius: BorderRadius.circular(KTokens.rSm),
        border: Border.all(color: KTokens.border),
      ),
      child: Column(
        children: [
          Text(
            '$day',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: KTokens.ink,
              height: 1,
            ),
          ),
          Text(
            month.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              color: KTokens.inkSoft,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.bg,
    required this.text,
    required this.label,
  });
  final Color bg;
  final Color text;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KTokens.rPill),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          letterSpacing: 0.8,
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
