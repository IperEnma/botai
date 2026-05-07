import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KTokens {
  KTokens._();

  static const bg             = Color(0xFFFBFAF7);
  static const surface        = Color(0xFFFFFFFF);
  static const ink            = Color(0xFF0F0F10);
  static const inkMuted       = Color(0xFF6B6B70);
  static const inkSoft        = Color(0xFF9A978F);
  static const inkPlaceholder = Color(0xFFBDBAB2);
  static const accent         = Color(0xFF3B2F63);
  static const accentSoft     = Color(0x143B2F63);
  static const border         = Color(0x14000000);
  static const borderStrong   = Color(0x1F000000);
  static const errorColor     = Color(0xFFB23A3A);

  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s7 = 32.0;
  static const s8 = 40.0;
  static const rSm   = 10.0;
  static const rMd   = 12.0;
  static const rPill = 999.0;

  static TextStyle get tQuestion =>
      GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: -0.5, color: ink);

  static TextStyle get tHint =>
      GoogleFonts.inter(fontSize: 14, height: 1.45, color: inkMuted);

  static TextStyle get tInput =>
      GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.2, color: ink);

  static TextStyle get tEyebrow =>
      GoogleFonts.jetBrainsMono(fontSize: 11, letterSpacing: 1.6, color: accent, fontWeight: FontWeight.w500);

  static TextStyle get tMonoHint =>
      GoogleFonts.jetBrainsMono(fontSize: 11, color: inkSoft);

  static TextStyle get tCta =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle get tSummaryLabel =>
      GoogleFonts.inter(fontSize: 13, color: inkMuted);

  static TextStyle get tSummaryValue =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: ink);

  static TextStyle get tError =>
      GoogleFonts.inter(fontSize: 12, color: errorColor);
}
