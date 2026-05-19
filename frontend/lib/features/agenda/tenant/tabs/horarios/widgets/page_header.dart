import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../features/agenda/register/konecta_tokens.dart';

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
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: KTokens.ink,
                    height: 1.1,
                  ),
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
              OutlinedButton.icon(
                onPressed: hasChanges && !isSaving ? onRevert : null,
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Revertir cambios'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KTokens.accent,
                  side: BorderSide(
                    color: hasChanges ? KTokens.accent : KTokens.border,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KTokens.rMd),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: hasChanges && !isSaving ? onSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KTokens.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor: KTokens.border,
                  disabledForegroundColor: KTokens.inkSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KTokens.rMd),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
