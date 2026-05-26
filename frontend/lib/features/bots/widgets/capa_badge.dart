import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/agenda/register/konecta_tokens.dart';
import '../models/bot.dart';

class CapaBadge extends StatelessWidget {
  const CapaBadge({super.key, required this.capa});
  final BotCapa capa;

  @override
  Widget build(BuildContext context) {
    final (bg, text, label) = switch (capa) {
      BotCapa.capa1 => (KTokens.capa1Bg, KTokens.capa1Text, 'CAPA 1 · FAQ'),
      BotCapa.capa2 =>
        (KTokens.capa2Bg, KTokens.capa2Text, 'CAPA 2 · IA HÍBRIDA'),
      BotCapa.capa3 =>
        (KTokens.capa3Bg, KTokens.capa3Text, 'CAPA 3 · CRM'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: text,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
