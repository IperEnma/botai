import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 768;

    final actions = [
      _QuickAction(
        icon: Icons.calendar_today_outlined,
        name: 'Nuevo turno',
        hint: 'AGENDAR MANUAL',
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.smart_toy_outlined,
        name: 'Crear bot',
        hint: 'WHATSAPP',
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.person_add_outlined,
        name: 'Agregar cliente',
        hint: 'BASE DE DATOS',
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.share_outlined,
        name: 'Compartir agenda',
        hint: 'LINK PÚBLICO',
        onTap: () {},
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCESOS RAPIDOS',
          style: KTokens.tEyebrow,
        ),
        const SizedBox(height: 12),
        if (isNarrow)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions
                .map(
                  (a) => SizedBox(
                    width: (MediaQuery.sizeOf(context).width - 76) / 2,
                    child: a,
                  ),
                )
                .toList(),
          )
        else
          Row(
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: actions[i]),
              ],
            ],
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.name,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String name;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: KTokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: KTokens.border),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: KTokens.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color: KTokens.inkSoft,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: KTokens.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: KTokens.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
