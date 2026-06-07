import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../register/konecta_tokens.dart';
import '../cliente.dart';

/// Tarjeta horizontal con los 4 KPIs del negocio, separados por divisores 1px.
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.kpis});

  final ClientesKpis kpis;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        final cells = [
          _Cell(value: '${kpis.total}', label: 'Clientes totales'),
          _Cell(value: '${kpis.nuevosEsteMes}', label: 'Nuevos este mes'),
          _Cell(
            value: '${(kpis.recurrencia * 100).round()}%',
            label: 'Tasa de recurrencia',
            accent: true,
          ),
          _Cell(
            value: kpis.visitasPromedio.toStringAsFixed(1).replaceAll('.', ','),
            label: 'Visitas promedio',
          ),
        ];

        final container = BoxDecoration(
          color: KTokens.surface,
          borderRadius: BorderRadius.circular(KTokens.rMd),
          border: Border.all(color: KTokens.border),
        );

        if (narrow) {
          return Container(
            decoration: container,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Row(
                    children: [cells[0], const _VDivider(), cells[1]],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: KTokens.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Row(
                    children: [cells[2], const _VDivider(), cells[3]],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: container,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              cells[0],
              const _VDivider(),
              cells[1],
              const _VDivider(),
              cells[2],
              const _VDivider(),
              cells[3],
            ],
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.label,
    this.accent = false,
  });

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: accent ? KTokens.accent : KTokens.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: KTokens.inkSoft,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: KTokens.border);
}
