import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cliente.dart';

/// Colores semánticos por etiqueta (§1).
class TagPalette {
  final Color fg;
  final Color bg;
  const TagPalette(this.fg, this.bg);

  static TagPalette of(ClienteTag tag) => switch (tag) {
        ClienteTag.vip => const TagPalette(
            Color(0xFF3B2F63),
            Color(0xFFECE8F6),
          ),
        ClienteTag.fiel => const TagPalette(
            Color(0xFF0A8C5B),
            Color(0xFFE3F5EC),
          ),
        ClienteTag.nuevo => const TagPalette(
            Color(0xFFE8731A),
            Color(0xFFFBEEE0),
          ),
      };
}

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.tag});

  final ClienteTag tag;

  @override
  Widget build(BuildContext context) {
    final p = TagPalette.of(tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag.label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: p.fg,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
