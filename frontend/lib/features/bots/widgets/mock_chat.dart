import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/agenda/register/konecta_tokens.dart';

class MockChat extends StatelessWidget {
  const MockChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2247), Color(0xFF3B2F63), Color(0xFF4A3A7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF281E46).withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WhatsApp header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: KTokens.waGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estudio Norte · Bot',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'EN LÍNEA',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      color: KTokens.waGreen,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chat bubbles
          _ClientBubble(
            text: 'Hola! Quiero un turno para mañana, ¿pueden hacer color?',
            time: '10:31',
          ),
          const SizedBox(height: 8),
          _BotBubble(
            text: '¡Hola! Sí, Lucía hace color 💜\nMañana tiene libres: 09:00, 14:00 y 16:30. ¿Cuál preferís?',
            time: '10:31',
          ),
          const SizedBox(height: 8),
          _ClientBubble(
            text: '14 me viene perfecto',
            time: '10:32',
          ),
          const SizedBox(height: 8),
          _BotBubble(
            text: 'Listo, te reservé el martes 20 a las 14:00 con Lucía. ✓',
            time: '10:32',
          ),
        ],
      ),
    );
  }
}

class _ClientBubble extends StatelessWidget {
  const _ClientBubble({required this.text, required this.time});
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.55),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: _BubbleContent(text: text, time: time, textColor: Colors.white),
      ),
    );
  }
}

class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.text, required this.time});
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.55),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: KTokens.bubbleBotBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: _BubbleContent(
            text: text, time: time, textColor: KTokens.bubbleBotText),
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({
    required this.text,
    required this.time,
    required this.textColor,
  });
  final String text;
  final String time;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: textColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          time,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: textColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
