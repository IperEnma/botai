import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../models/business_category.dart';

class CategoryBar extends StatelessWidget {
  const CategoryBar({
    super.key,
    required this.categories,
    required this.onChangeCategory,
  });

  final List<BusinessCategory> categories;
  final VoidCallback onChangeCategory;

  @override
  Widget build(BuildContext context) {
    final label = categories.length > 1
        ? 'CATEGORÍAS DEL NEGOCIO'
        : 'CATEGORÍA DEL NEGOCIO';
    final list = categories.isEmpty ? const [BusinessCategory.otra] : categories;

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
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              letterSpacing: 1.4,
              color: KTokens.inkSoft,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final c in list) _CategoryPill(name: c.displayName),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Define las sugerencias disponibles',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: KTokens.inkMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          GestureDetector(
            onTap: onChangeCategory,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  categories.length > 1 ? 'Cambiar categorías' : 'Cambiar categoría',
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

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            name,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: KTokens.accent,
            ),
          ),
        ],
      ),
    );
  }
}
