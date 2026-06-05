import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../register/konecta_tokens.dart';
import '../cliente.dart';

class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.cliente, required this.now});

  final Cliente cliente;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final inasistencias = cliente.inasistencias;
    final color = inasistencias > 0
        ? const Color(0xFFC0392B)
        : const Color(0xFF0A8C5B);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                value: '${cliente.visitas}',
                label: 'Reservas totales',
                accentSoftBg: true,
                valueColor: KTokens.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                value: '\$ ${_money(cliente.gastoAcumulado)}',
                label: 'Gasto acumulado',
                tight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                value: relativeDay(cliente.ultimaVisita, now),
                label: 'Última visita',
                tight: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                value: '$inasistencias',
                label: 'Inasistencias',
                valueColor: color,
                semanticsHint: inasistencias > 0
                    ? '$inasistencias inasistencias'
                    : 'sin inasistencias',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.value,
    required this.label,
    this.accentSoftBg = false,
    this.valueColor,
    this.tight = false,
    this.semanticsHint,
  });

  final String value;
  final String label;
  final bool accentSoftBg;
  final Color? valueColor;
  final bool tight;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final fontSize = tight ? 20.0 : 26.0;
    return Semantics(
      label: semanticsHint != null ? '$label · $semanticsHint' : '$label · $value',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: accentSoftBg ? const Color(0xFFECE8F6) : KTokens.surface,
          borderRadius: BorderRadius.circular(KTokens.rMd),
          border: Border.all(
            color: accentSoftBg
                ? Colors.transparent
                : KTokens.border,
          ),
        ),
        height: 86,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: valueColor ?? KTokens.ink,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: KTokens.inkSoft,
              ),
            ),
          ],
        ),
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
