import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../models/business_category.dart';

class CategoryBar extends StatelessWidget {
  const CategoryBar({
    super.key,
    required this.category,
    required this.onChangeCategory,
  });

  final BusinessCategory category;
  final VoidCallback onChangeCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Text(
            'CATEGORÍA DEL NEGOCIO',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              letterSpacing: 1.4,
              color: KTokens.inkSoft,
            ),
          ),
          const SizedBox(width: 12),

          // Category pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x143B2F63),
              borderRadius: BorderRadius.circular(KTokens.rPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: KTokens.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: KTokens.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          Text(
            'Define qué sub-categorías y sugerencias aparecen',
            style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkMuted),
          ),
          const Spacer(),

          // Change category button
          GestureDetector(
            onTap: onChangeCategory,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cambiar categoría',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: KTokens.accent,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 14, color: KTokens.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
