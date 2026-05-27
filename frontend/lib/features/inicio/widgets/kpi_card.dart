import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import 'trend_chip.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.trendPct,
    required this.breakdown,
  });

  final String label;
  final String value;
  final String unit;
  final double trendPct;
  final Widget breakdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KTokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KTokens.border),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: KTokens.tEyebrow,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 36,
                    fontStyle: FontStyle.italic,
                    color: KTokens.ink,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: KTokens.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: TrendChip(pct: trendPct),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: KTokens.border),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: breakdown,
          ),
        ],
      ),
    );
  }
}
