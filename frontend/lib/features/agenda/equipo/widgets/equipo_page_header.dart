import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../register/konecta_tokens.dart';

class EquipoPageHeader extends StatelessWidget {
  const EquipoPageHeader({
    super.key,
    required this.onAddMember,
    required this.onImport,
  });

  final VoidCallback onAddMember;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEGOCIO',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: KTokens.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Equipo',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontStyle: FontStyle.italic,
                  color: KTokens.ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              _DescriptionText(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_outlined, size: 16),
              label: const Text('Importar lista'),
              style: OutlinedButton.styleFrom(
                foregroundColor: KTokens.ink,
                side: const BorderSide(color: KTokens.ink, width: 1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KTokens.rSm),
                ),
                textStyle: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onAddMember,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar miembro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KTokens.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KTokens.rSm),
                ),
                textStyle: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DescriptionText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
        children: [
          const TextSpan(
            text:
                'Tu gente, qué hacen y cuándo trabajan. El horario de cada uno se intersecta con el del negocio en ',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () {},
              child: Text(
                'Horarios',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: KTokens.accent,
                  decoration: TextDecoration.underline,
                  decorationColor: KTokens.accent,
                ),
              ),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
