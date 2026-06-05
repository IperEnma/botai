import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../register/konecta_tokens.dart';
import '../../../../shared/k_button.dart';
import '../cliente.dart';
import '../widgets/cliente_row.dart';
import 'historial_list.dart';
import 'kpi_grid.dart';
import 'servicios_bars.dart';

class FichaPanel extends StatelessWidget {
  const FichaPanel({
    super.key,
    required this.cliente,
    required this.now,
    required this.onAgendar,
    required this.onWhatsapp,
    this.compact = false,
  });

  final Cliente cliente;
  final DateTime now;
  final VoidCallback onAgendar;
  final VoidCallback onWhatsapp;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KTokens.surface,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 22,
          compact ? 16 : 32,
          compact ? 16 : 22,
          compact ? 24 : 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ─────────────────────────────────────────────────────
            Row(
              children: [
                ClienteAvatar(cliente: cliente, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: KTokens.tHero,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${cliente.telefono} · CLIENTE DESDE ${monthYear(cliente.clienteDesde)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          color: KTokens.inkSoft,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Acciones ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: KButton.primary(
                    label: 'Agendar',
                    icon: Icons.add_rounded,
                    onPressed: onAgendar,
                    expand: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KButton.secondary(
                    label: 'WhatsApp',
                    icon: Icons.chat_bubble_outline,
                    onPressed: onWhatsapp,
                    expand: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const _Eyebrow('RESUMEN'),
            const SizedBox(height: 10),
            KpiGrid(cliente: cliente, now: now),

            const SizedBox(height: 24),
            const _Eyebrow('SERVICIOS MÁS USADOS'),
            const SizedBox(height: 12),
            ServiciosBars(servicios: cliente.servicios),

            const SizedBox(height: 24),
            const _Eyebrow('HISTORIAL RECIENTE'),
            const SizedBox(height: 4),
            HistorialList(historial: cliente.historial),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          letterSpacing: 1.4,
          color: KTokens.inkSoft,
          fontWeight: FontWeight.w500,
        ),
      );
}
