import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema y layout compartido para `/reservar` (marca → sucursal → turno).
class PublicReservarTheme {
  PublicReservarTheme({
    required this.primary,
    required this.background,
    required this.card,
    required this.dark,
    this.fontFamily = 'Roboto',
    this.logoUrl,
  });

  final Color primary;
  final Color background;
  final Color card;
  final bool dark;
  final String fontFamily;
  final String? logoUrl;

  Color get text => dark ? Colors.white : const Color(0xFF0F172A);
  Color get textSub => dark ? Colors.white70 : const Color(0xFF64748B);
  Color get cardFill =>
      dark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF8FAFC);
  Color get cardBorder =>
      dark ? Colors.white12 : const Color(0xFFE2E8F0);
  Color get surface => card;

  Color get primarySoft => primary.withValues(alpha: 0.12);

  List<Color> get primaryGradient => [
        primary,
        Color.lerp(primary, const Color(0xFF8B5CF6), 0.35) ?? primary,
      ];

  static PublicReservarTheme fromHex({
    String? colorPrimario,
    String? colorFondo,
    String? colorTarjeta,
    String? fontFamily,
    String? logoUrl,
  }) {
    final background = _colorFromHex(colorFondo, const Color(0xFFFBFAF7));
    return PublicReservarTheme(
      primary: _colorFromHex(colorPrimario, const Color(0xFF6366F1)),
      background: background,
      card: _colorFromHex(colorTarjeta, Colors.white),
      dark: background.computeLuminance() < 0.4,
      fontFamily: fontFamily ?? 'Roboto',
      logoUrl: logoUrl,
    );
  }

  /// Tema fijo del flujo público por slug (perfil + reserva + mis turnos).
  static PublicReservarTheme felito({String? logoUrl}) {
    return PublicReservarTheme(
      primary: const Color(0xFF7C5CFF),
      background: const Color(0xFFF3F4F6),
      card: Colors.white,
      dark: false,
      fontFamily: 'Inter',
      logoUrl: logoUrl,
    );
  }

  static Color _colorFromHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6) return fallback;
    final val = int.tryParse('FF$cleaned', radix: 16);
    return val != null ? Color(val) : fallback;
  }

  TextStyle textStyle({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) {
    if (fontFamily == 'Inter') {
      return GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
      );
    }
    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
      );
    }
  }
}

/// Título del paso dentro del scroll.
Widget publicReservarScrollSectionTitle({
  required PublicReservarTheme theme,
  required String title,
  String? subtitle,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textStyle(size: 24, weight: FontWeight.w700),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textStyle(size: 14, color: theme.textSub),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Tarjeta de sucursal (nombre + dirección).
class PublicBranchTile extends StatelessWidget {
  const PublicBranchTile({
    super.key,
    required this.nombre,
    this.direccion,
    required this.theme,
    required this.onTap,
  });

  final String nombre;
  final String? direccion;
  final PublicReservarTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: t.textStyle(
                        size: 16,
                        weight: FontWeight.w600,
                      ),
                    ),
                    if (direccion != null && direccion!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        direccion!,
                        style: t.textStyle(size: 14, color: t.textSub),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
