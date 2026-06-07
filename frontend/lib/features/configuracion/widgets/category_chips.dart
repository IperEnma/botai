import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/register/konecta_tokens.dart';

const _kAccentDot = Color(0xFF7C5CD6);

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key, required this.categorias});

  final List<String> categorias;

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty) {
      return Text(
        'Sin categorías',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: KTokens.inkPlaceholder,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final cat in categorias) _CategoryChip(label: cat),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: KTokens.accentSoft,
        borderRadius: BorderRadius.circular(KTokens.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _kAccentDot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: KTokens.accent,
            ),
          ),
        ],
      ),
    );
  }
}
