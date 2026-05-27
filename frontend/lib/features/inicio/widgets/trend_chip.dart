import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';

class TrendChip extends StatelessWidget {
  const TrendChip({super.key, required this.pct});

  final double pct;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    if (pct > 0) {
      bg = KTokens.excOpenBg;
      fg = KTokens.trendUp;
      label = '↑ +${pct.toStringAsFixed(0)}%';
    } else if (pct < 0) {
      bg = const Color(0x1FEF4444);
      fg = KTokens.trendDown;
      label = '↓ ${pct.toStringAsFixed(0)}%';
    } else {
      bg = const Color(0x0D000000);
      fg = KTokens.trendNeutral;
      label = '—';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
