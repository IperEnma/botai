import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgendaTokens {
  AgendaTokens._();

  // ── Paleta principal ─────────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF6366F1); // indigo-500
  static const Color primaryDark = Color(0xFF4F46E5); // indigo-600
  static const Color accent      = Color(0xFF8B5CF6); // violet-500
  static const Color dark        = Color(0xFF0F172A); // slate-900
  static const Color surface     = Color(0xFFF8FAFC); // slate-50
  static const Color textMuted   = Color(0xFF64748B); // slate-500

  // Tiers de plan
  static const Color tierVip    = Color(0xFFF59E0B); // amber-500
  static const Color tierGolden = Color(0xFFEAB308); // yellow-500
  static const Color tierPlata  = Color(0xFF94A3B8); // slate-400

  // Semáforo de créditos / saldo
  static const Color creditPositive = Color(0xFF22C55E);
  static const Color creditNegative = Color(0xFFEF4444);
  static const Color creditNeutral  = Color(0xFF64748B);

  // Estados de booking (alineados con BookingEstado)
  static const Color bookingScheduled = Color(0xFF3B82F6);
  static const Color bookingConfirmed = Color(0xFF22C55E);
  static const Color bookingCancelled = Color(0xFFEF4444);
  static const Color bookingCompleted = Color(0xFF8B5CF6);
  static const Color bookingNoShow    = Color(0xFF94A3B8);

  // ── Layout ───────────────────────────────────────────────────────────────────
  static const double maxWidth   = 1200.0;
  static const double breakpoint =  800.0;

  static const double cardRadius   = 16.0;
  static const double chipRadius   = 20.0;
  static const double dialogRadius = 20.0;

  static const EdgeInsets cardPadding   = EdgeInsets.all(16);
  static const EdgeInsets screenPadding = EdgeInsets.all(24);

  // ── Tipografía (Poppins) ─────────────────────────────────────────────────────
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );

  // Atajos tipográficos frecuentes
  static TextStyle get heading => poppins(fontSize: 22, fontWeight: FontWeight.w700, color: dark);
  static TextStyle get subheading => poppins(fontSize: 16, fontWeight: FontWeight.w600, color: dark);
  static TextStyle get body => poppins(fontSize: 14, color: dark);
  static TextStyle get muted => poppins(fontSize: 13, color: textMuted);
  static TextStyle get appBarTitle => poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white);

  // ── AppBar preconfigurado ────────────────────────────────────────────────────
  static AppBar styledAppBar({
    required Widget title,
    List<Widget>? actions,
    Widget? leading,
    PreferredSizeWidget? bottom,
    bool? centerTitle,
  }) =>
      AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: centerTitle,
        title: title,
        actions: actions,
        leading: leading,
        bottom: bottom,
      );

  // ── Helpers responsive ───────────────────────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < breakpoint;
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpoint;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= maxWidth;
}
