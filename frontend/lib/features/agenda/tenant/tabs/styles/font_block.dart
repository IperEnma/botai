import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../register/konecta_tokens.dart';

/// Renderiza el nombre de la fuente en su propia tipografía.
TextStyle fontPreviewStyle(String family, {required Color color, double size = 14}) {
  try {
    return GoogleFonts.getFont(
      family,
      fontSize: size,
      color: color,
    );
  } catch (_) {
    return TextStyle(fontFamily: family, fontSize: size, color: color);
  }
}

class FontBlock extends StatelessWidget {
  const FontBlock({
    super.key,
    required this.fonts,
    required this.value,
    required this.onChanged,
  });

  final List<String> fonts;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        for (final font in fonts)
          _FontChip(
            family: font,
            selected: font == value,
            onTap: () => onChanged(font),
          ),
      ],
    );
  }
}

class _FontChip extends StatelessWidget {
  const _FontChip({
    required this.family,
    required this.selected,
    required this.onTap,
  });

  final String family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tipografía $family',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? KTokens.accent : KTokens.surface,
            borderRadius: BorderRadius.circular(KTokens.rMd),
            border: Border.all(
              color: selected ? KTokens.accent : KTokens.borderStrong,
            ),
          ),
          child: Text(
            family,
            style: fontPreviewStyle(
              family,
              color: selected ? Colors.white : KTokens.ink,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }
}
