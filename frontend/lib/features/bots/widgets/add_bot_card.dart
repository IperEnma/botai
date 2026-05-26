import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/agenda/register/konecta_tokens.dart';

class AddBotCard extends StatefulWidget {
  const AddBotCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  State<AddBotCard> createState() => _AddBotCardState();
}

class _AddBotCardState extends State<AddBotCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          constraints: const BoxConstraints(minHeight: 220),
          decoration: BoxDecoration(
            color: _hovering
                ? KTokens.accentSoft.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovering
                  ? KTokens.accent.withValues(alpha: 0.3)
                  : const Color(0x26000000),
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: KTokens.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '+',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      color: KTokens.accent,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Crear otro bot',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: KTokens.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Especializado para otra tarea',
                style: GoogleFonts.inter(
                  fontSize: 12,
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
