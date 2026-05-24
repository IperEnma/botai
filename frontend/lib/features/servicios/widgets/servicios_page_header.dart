import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';

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
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontStyle: FontStyle.italic,
                  color: KTokens.ink,
                  height: 1.1,
                ),
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
            OutlinedButton(
              onPressed: onImport,
              style: OutlinedButton.styleFrom(
                foregroundColor: KTokens.ink,
                side: const BorderSide(color: KTokens.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KTokens.rSm),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('⎘  Importar catálogo'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: KTokens.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KTokens.rSm),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('+ Agregar servicio'),
            ),
          ],
        ),
      ],
    );
  }
}
