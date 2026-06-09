import 'package:flutter/material.dart';

/// Estilo de marca configurable por el dueño del negocio.
/// Solo afecta la vista previa (cara pública), nunca el panel admin.
class BrandStyle {
  static const int maxPhotos = 8;

  final String? logoUrl;
  final String primaryColor;
  final String backgroundColor;
  final String cardColor;
  final String fontFamily;
  final List<String> workPhotos;

  const BrandStyle({
    this.logoUrl,
    this.primaryColor = '#3b2f63',
    this.backgroundColor = '#fbfaf7',
    this.cardColor = '#ffffff',
    this.fontFamily = 'Inter',
    this.workPhotos = const [],
  });

  BrandStyle copyWith({
    Object? logoUrl = _sentinel,
    String? primaryColor,
    String? backgroundColor,
    String? cardColor,
    String? fontFamily,
    List<String>? workPhotos,
  }) {
    return BrandStyle(
      logoUrl: identical(logoUrl, _sentinel) ? this.logoUrl : logoUrl as String?,
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cardColor: cardColor ?? this.cardColor,
      fontFamily: fontFamily ?? this.fontFamily,
      workPhotos: workPhotos ?? this.workPhotos,
    );
  }

  static const _sentinel = Object();
}

// ─── Color helpers ────────────────────────────────────────────────────────────

/// Parsea hex `#RRGGBB` o `RRGGBB` → Color. Devuelve [fallback] si falla.
Color parseHex(String hex, {Color fallback = Colors.black}) {
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6) return fallback;
  final n = int.tryParse('FF$cleaned', radix: 16);
  return n == null ? fallback : Color(n);
}

/// `0.299·R + 0.587·G + 0.114·B < 110` ⇒ fondo oscuro.
bool isDark(String hex) {
  final c = parseHex(hex);
  final r = (c.toARGB32() >> 16) & 0xFF;
  final g = (c.toARGB32() >> 8) & 0xFF;
  final b = c.toARGB32() & 0xFF;
  return (0.299 * r + 0.587 * g + 0.114 * b) < 110;
}

/// Mezcla [hex] hacia blanco en proporción [t] (0.0–1.0).
/// `lighten('#3b2f63', 0.55)` ≈ #9c95b8.
Color lighten(String hex, double t) {
  final c = parseHex(hex);
  final r = ((c.toARGB32() >> 16) & 0xFF);
  final g = ((c.toARGB32() >> 8) & 0xFF);
  final b = (c.toARGB32() & 0xFF);
  int mix(int channel) => (channel + (255 - channel) * t).round().clamp(0, 255);
  return Color.fromARGB(255, mix(r), mix(g), mix(b));
}

/// Normaliza un input HEX a `#RRGGBB` (uppercase). Devuelve `null` si no es válido.
String? normalizeHex(String raw) {
  final cleaned = raw.replaceAll('#', '').trim().toUpperCase();
  if (cleaned.length != 6) return null;
  if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(cleaned)) return null;
  return '#$cleaned';
}

// ─── Datos curados (de la guía) ──────────────────────────────────────────────

const primaryPalette = <String>[
  '#3B2F63', '#7C5CD6', '#E84393', '#16A085',
  '#27AE60', '#F1A417', '#E74C3C', '#2F6FDB',
  '#8AC926', '#1AA3D6', '#E8731A', '#5A6472',
];

const cardPalette = <String>[
  '#FFFFFF', '#FBFAF7', '#EEF1F6', '#EEF6EE',
  '#EEF2FB', '#FBEEF6', '#FBEEE6', '#F8FAFC',
];

const bgPalette = <String>[
  '#FFFFFF', '#FBFAF7', '#EEF1F6', '#1C2230',
  '#0F1115', '#161018', '#FBEEE6', '#EEF6EE',
  '#EEF2FB', '#FBEEF6',
];

const fontFamilies = <String>[
  'Inter',
  'Instrument Serif',
  'Montserrat',
  'Poppins',
  'Lato',
  'Open Sans',
  'Oswald',
  'Raleway',
];
