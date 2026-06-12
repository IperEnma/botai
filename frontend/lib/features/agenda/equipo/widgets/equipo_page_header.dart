import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../register/konecta_tokens.dart';
import '../../shared/k_button.dart';

class EquipoPageHeader extends StatelessWidget {
  const EquipoPageHeader({
    super.key,
    required this.onAddMember,
    required this.onImport,
    this.canManageStaff = true,
  });

  final VoidCallback onAddMember;
  final VoidCallback onImport;

  /// Gate RBAC: si `false`, ocultamos los botones de mutación (gestión de
  /// staff es OWNER/TENANT_ADMIN). El componente sigue mostrando el título y
  /// la descripción para usuarios de solo lectura (RECEPTION/STAFF_VIEWER).
  final bool canManageStaff;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 700;

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Equipo', style: KTokens.tDisplay),
        if (!isNarrow) ...[
          const SizedBox(height: 8),
          _DescriptionText(),
        ],
      ],
    );

    if (!canManageStaff) {
      // Vista de solo lectura: sin botones, solo el título.
      return textBlock;
    }

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
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
                label: 'Importar lista',
                icon: Icons.upload_outlined,
                compact: true,
                onPressed: onImport,
              ),
              const Spacer(),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: textBlock),
        const SizedBox(width: 16),
        buttons,
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
