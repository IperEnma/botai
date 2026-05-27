import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../models/kpi_models.dart';

class TurnoRow extends StatelessWidget {
  const TurnoRow({
    super.key,
    required this.turno,
    required this.isPast,
  });

  final TurnoSummary turno;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(turno.time);

    return Opacity(
      opacity: isPast ? 0.5 : 1.0,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: KTokens.border, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                timeStr,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: KTokens.inkMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 15,
              backgroundColor:
                  turno.professionalColor.withValues(alpha: 0.18),
              child: Text(
                turno.clientInitials,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: turno.professionalColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turno.clientName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: KTokens.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    turno.serviceLabel,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: KTokens.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _BranchBadge(name: turno.branchName),
            const SizedBox(width: 6),
            _StatusBadge(status: turno.status),
          ],
        ),
      ),
    );
  }
}

class _BranchBadge extends StatelessWidget {
  const _BranchBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x0D000000),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KTokens.borderStrong),
      ),
      child: Text(
        name,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          color: KTokens.ink,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TurnoStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case TurnoStatus.confirmado:
        bg = KTokens.stateConfirmedBg;
        fg = KTokens.stateConfirmedText;
        label = '✓ CONF';
      case TurnoStatus.pendiente:
        bg = KTokens.statePendingBg;
        fg = KTokens.statePendingText;
        label = '◯ PEND';
      case TurnoStatus.cancelado:
        bg = KTokens.stateCanceledBg;
        fg = KTokens.stateCanceledText;
        label = '✕ CANC';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
