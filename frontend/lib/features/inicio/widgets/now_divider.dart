import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../agenda/register/konecta_tokens.dart';

class NowDivider extends StatelessWidget {
  const NowDivider({super.key, required this.nextCount});

  final int nextCount;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0x0AEF4444),
        border: Border.symmetric(
          horizontal: BorderSide(color: KTokens.nowIndicator, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: KTokens.nowIndicator,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'AHORA · $timeStr',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: KTokens.nowIndicator,
            ),
          ),
          const Spacer(),
          Text(
            'SIGUIENTES $nextCount TURNOS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: KTokens.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
