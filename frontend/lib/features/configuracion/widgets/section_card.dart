import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/register/konecta_tokens.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow,
    this.hint,
    this.onEdit,
  });

  final String title;
  final Widget child;
  final String? eyebrow;
  final String? hint;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KTokens.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!.toUpperCase(),
              style: KTokens.tEyebrow,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: KTokens.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        hint!,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: KTokens.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: 12),
                _EditButton(onTap: onEdit!),
              ],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: KTokens.surface,
            borderRadius: BorderRadius.circular(KTokens.rPill),
            border: Border.all(color: KTokens.borderStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 13,
                color: KTokens.inkMuted,
              ),
              const SizedBox(width: 5),
              Text(
                'Editar',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: KTokens.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
