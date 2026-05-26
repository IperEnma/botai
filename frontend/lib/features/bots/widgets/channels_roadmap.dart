import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/agenda/register/konecta_tokens.dart';

class ChannelsRoadmap extends StatelessWidget {
  const ChannelsRoadmap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'CANALES',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: KTokens.inkSoft,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          // WhatsApp active
          _ActiveChip(),
          const SizedBox(width: 8),
          // Upcoming channels
          _UpcomingChip(label: 'Telegram', icon: Icons.telegram),
          const SizedBox(width: 8),
          _UpcomingChip(label: 'Widget web', icon: Icons.web),
          const SizedBox(width: 8),
          _UpcomingChip(
              label: 'Instagram DM',
              icon: Icons.camera_alt_outlined,
              badge: 'EXPLORANDO'),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatefulWidget {
  @override
  State<_ActiveChip> createState() => _ActiveChipState();
}

class _ActiveChipState extends State<_ActiveChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1100),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: KTokens.waGreenSoft,
        borderRadius: BorderRadius.circular(KTokens.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, w) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: KTokens.waGreen.withValues(alpha: _anim.value),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'WhatsApp Business',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: KTokens.waGreenText,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingChip extends StatelessWidget {
  const _UpcomingChip({
    required this.label,
    required this.icon,
    this.badge = 'PRÓXIMO',
  });
  final String label;
  final IconData icon;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KTokens.rPill),
        border: Border.all(
          color: KTokens.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: KTokens.inkSoft),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: KTokens.inkSoft,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: KTokens.bg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: KTokens.inkSoft,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
