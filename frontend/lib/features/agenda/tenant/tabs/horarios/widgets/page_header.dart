import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../../../../features/agenda/shared/k_button.dart';

class HorariosPageHeader extends StatelessWidget {
  const HorariosPageHeader({
    super.key,
    required this.hasChanges,
    required this.isSaving,
    required this.onSave,
    required this.onRevert,
  });

  final bool hasChanges;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onRevert;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONFIGURACIÓN',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    letterSpacing: 1.6,
                    color: KTokens.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Horarios',
                  style: KTokens.tDisplay,
                ),
                const SizedBox(height: 8),
                Text(
                  'Definí cuándo tu negocio acepta turnos. Lo que configures acá aplica a todo el negocio.',
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
            mainAxisSize: MainAxisSize.min,
            children: [
              KButton.secondary(
                label: 'Revertir cambios',
                icon: Icons.history,
                compact: true,
                onPressed: hasChanges && !isSaving ? onRevert : null,
              ),
              const SizedBox(width: 8),
              KButton.primary(
                label: 'Guardar cambios',
                icon: Icons.check_rounded,
                compact: true,
                loading: isSaving,
                onPressed: hasChanges && !isSaving ? onSave : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
