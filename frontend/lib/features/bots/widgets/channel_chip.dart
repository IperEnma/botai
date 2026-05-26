import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/agenda/register/konecta_tokens.dart';
import '../models/bot.dart';

class ChannelChip extends StatelessWidget {
  const ChannelChip({super.key, required this.channel, this.active = true});
  final BotChannel channel;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final label = switch (channel) {
      BotChannel.whatsapp => 'WhatsApp',
      BotChannel.telegram => 'Telegram',
      BotChannel.web => 'Web',
      BotChannel.instagram => 'Instagram',
    };

    final bg = active ? KTokens.waGreenSoft : const Color(0x0C000000);
    final fg = active ? KTokens.waGreenText : KTokens.inkSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) ...[
            _PulseDot(),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, w) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: KTokens.waGreen.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
