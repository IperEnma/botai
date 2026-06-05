import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../../agenda/shared/k_button.dart';

class ServiciosPageHeader extends StatelessWidget {
  const ServiciosPageHeader({
    super.key,
    required this.onAdd,
    required this.onImport,
  });

  final VoidCallback onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEGOCIO',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: KTokens.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Servicios',
                style: KTokens.tDisplay,
              ),
              const SizedBox(height: 8),
              Text(
                'Lo que ofrecés a tus clientes. Cada servicio define duración, precio y quién lo puede atender.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: KTokens.inkMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            KButton.secondary(
              label: 'Importar catálogo',
              icon: Icons.upload_file_outlined,
              compact: true,
              onPressed: onImport,
            ),
            const SizedBox(width: 8),
            KButton.primary(
              label: 'Agregar servicio',
              icon: Icons.add_rounded,
              compact: true,
              onPressed: onAdd,
            ),
          ],
        ),
      ],
    );
  }
}
