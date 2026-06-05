import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../register/konecta_tokens.dart';
import '../../shared/k_button.dart';

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
                style: KTokens.tDisplay,
              ),
              const SizedBox(height: 8),
              _DescriptionText(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            KButton.secondary(
              label: 'Importar lista',
              icon: Icons.upload_outlined,
              compact: true,
              onPressed: onImport,
            ),
            const SizedBox(width: 8),
            KButton.primary(
              label: 'Agregar miembro',
              icon: Icons.add_rounded,
              compact: true,
              onPressed: onAddMember,
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
