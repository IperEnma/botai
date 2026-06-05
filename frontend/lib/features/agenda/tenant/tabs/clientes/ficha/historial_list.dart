import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../register/konecta_tokens.dart';
import '../cliente.dart';

class HistorialList extends StatelessWidget {
  const HistorialList({super.key, required this.historial, this.maxItems = 5});

  final List<TurnoHist> historial;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    if (historial.isEmpty) {
      return Text(
        'Sin historial reciente',
        style: GoogleFonts.inter(
          fontSize: 12.5,
          color: KTokens.inkSoft,
        ),
      );
    }

    final sorted = [...historial]..sort((a, b) => b.fecha.compareTo(a.fecha));
    final shown = sorted.take(maxItems).toList();
    final remaining = sorted.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, color: KTokens.border),
          _HistRow(item: shown[i]),
        ],
        if (remaining > 0) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: KTokens.accent,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ver todo ($remaining más)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: KTokens.accent,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HistRow extends StatelessWidget {
  const _HistRow({required this.item});

  final TurnoHist item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Text(
              shortDate(item.fecha),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                color: KTokens.inkSoft,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.servicio,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: KTokens.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'con ${item.profesional}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: KTokens.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$ ${_money(item.precio)}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12.5,
              color: KTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}

String _money(double v) {
  final whole = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final pos = whole.length - i;
    buf.write(whole[i]);
    if (pos > 1 && (pos - 1) % 3 == 0) buf.write('.');
  }
  return buf.toString();
}
