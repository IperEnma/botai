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
    final isNarrow = MediaQuery.sizeOf(context).width < 700;

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Servicios', style: KTokens.tDisplay),
        if (!isNarrow) ...[
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
      ],
    );

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
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
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textBlock,
          const SizedBox(height: 16),
          Row(
            children: [
              KButton.secondary(
                label: 'Importar catálogo',
                icon: Icons.upload_file_outlined,
                compact: true,
                onPressed: onImport,
              ),
              const Spacer(),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: textBlock),
        const SizedBox(width: 24),
        buttons,
      ],
    );
  }
}
