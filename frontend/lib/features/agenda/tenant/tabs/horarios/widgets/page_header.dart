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
    final isNarrow = MediaQuery.sizeOf(context).width < 700;

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Horarios', style: KTokens.tDisplay),
        const SizedBox(height: 8),
        Text(
          'Definí cuándo tu negocio acepta turnos. Lo que configures acá aplica a todo el negocio.',
          style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted, height: 1.5),
        ),
      ],
    );

    final buttons = Row(
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
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(isNarrow ? 20 : 32, 28, isNarrow ? 20 : 32, 0),
      child: isNarrow
          ? textBlock
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: textBlock),
                const SizedBox(width: 24),
                buttons,
              ],
            ),
    );
  }
}
