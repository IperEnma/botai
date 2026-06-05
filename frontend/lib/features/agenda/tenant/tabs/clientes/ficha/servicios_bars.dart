import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../register/konecta_tokens.dart';
import '../cliente.dart';

class ServiciosBars extends StatelessWidget {
  const ServiciosBars({super.key, required this.servicios});

  final List<ServicioUso> servicios;

  @override
  Widget build(BuildContext context) {
    if (servicios.isEmpty) {
      return Text(
        'Sin servicios registrados',
        style: GoogleFonts.inter(
          fontSize: 12.5,
          color: KTokens.inkSoft,
        ),
      );
    }

    final sorted = [...servicios]..sort((a, b) => b.veces.compareTo(a.veces));
    final max = sorted.first.veces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sorted.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _ServicioRow(item: sorted[i], max: max),
        ],
      ],
    );
  }
}

class _ServicioRow extends StatelessWidget {
  const _ServicioRow({required this.item, required this.max});

  final ServicioUso item;
  final int max;

  @override
  Widget build(BuildContext context) {
    final fraction = (max <= 0) ? 0.0 : item.veces / max;
    return Semantics(
      label: '${item.servicio}: ${item.veces} veces',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              item.servicio,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: KTokens.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(KTokens.rPill),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: KTokens.accentSoft,
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: KTokens.accent,
                        borderRadius: BorderRadius.circular(KTokens.rPill),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 28,
            child: Text(
              '${item.veces}×',
              textAlign: TextAlign.end,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: KTokens.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
