import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';

class TrendIndicator extends StatelessWidget {
  const TrendIndicator({super.key, required this.trend});

  final double trend;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;

    if (trend > 0.005) {
      text = '↑${(trend * 100).round()}%';
      color = KTokens.trendUp;
    } else if (trend < -0.005) {
      text = '↓${(-trend * 100).round()}%';
      color = KTokens.trendDown;
    } else {
      text = '—';
      color = KTokens.trendNeutral;
    }

    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(fontSize: 10, color: color),
    );
  }
}
