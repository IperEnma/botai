import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../register/konecta_tokens.dart';
import '../models/member.dart';

class MemberStatusBadge extends StatelessWidget {
  const MemberStatusBadge({super.key, required this.status});

  final MemberStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, text, label) = switch (status) {
      MemberStatus.activo => (
          KTokens.memberActiveBg,
          KTokens.memberActiveText,
          'ACTIVO',
        ),
      MemberStatus.pausado => (
          KTokens.memberPausedBg,
          KTokens.memberPausedText,
          'PAUSADO',
        ),
      MemberStatus.archivado => (
          KTokens.memberArchivedBg,
          KTokens.memberArchivedText,
          'ARCHIVADO',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KTokens.rPill),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          color: text,
        ),
      ),
    );
  }
}
