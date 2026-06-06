import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/agenda/register/konecta_tokens.dart';

// SVG path data (SimpleIcons, viewBox 0 0 24 24)
const _kPathWhatsApp =
    'M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15'
    '-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463'
    '-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606'
    '.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025'
    '-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008'
    '-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0'
    ' 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262'
    '.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413'
    '.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347'
    'm-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998'
    '-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884'
    ' 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437'
    ' 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335'
    '.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882'
    ' 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0'
    ' 00-3.48-8.413z';

const _kPathTelegram =
    'M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0'
    ' 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1'
    ' .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9'
    '-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124'
    '-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23'
    '.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061'
    ' 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245'
    '-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529'
    ' 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z';

const _kPathInstagram =
    'M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058'
    ' 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664'
    ' 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07'
    '-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204'
    '.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645'
    '-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618'
    '-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2'
    ' 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668'
    '-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073'
    '-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98'
    '-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162'
    's2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162'
    '-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0'
    ' 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44'
    ' 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z';

const _kPathChrome =
    'M12 0C8.21 0 4.831 1.757 2.632 4.501l3.953 6.848A5.454 5.454 0 0 1 12'
    ' 6.545h10.691A12 12 0 0 0 12 0zM1.931 5.47A11.943 11.943 0 0 0 0 12c0'
    ' 6.012 4.42 10.991 10.189 11.864l3.953-6.847a5.45 5.45 0 0 1-6.865-2.29z'
    'm13.342 2.166a5.446 5.446 0 0 1 1.45 7.09l.002.001h-.002l-5.344 9.257c'
    '.206.01.413.016.621.016 6.627 0 12-5.373 12-12 0-1.54-.29-3.011-.818'
    '-4.364zM12 10.545a1.455 1.455 0 1 0 0 2.91 1.455 1.455 0 0 0 0-2.91z';

Widget _brandSvg(String pathD, Color color, double size) => SvgPicture.string(
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
      '<path d="$pathD"/>'
      '</svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

class ChannelsRoadmap extends StatelessWidget {
  const ChannelsRoadmap({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        final chips = [
          _ActiveChip(iconOnly: isNarrow),
          const SizedBox(width: 8),
          _UpcomingChip(
            label: 'Telegram',
            pathD: _kPathTelegram,
            color: const Color(0xFF2CA5E0),
            iconOnly: isNarrow,
          ),
          const SizedBox(width: 8),
          _UpcomingChip(
            label: 'Widget web',
            pathD: _kPathChrome,
            color: KTokens.inkSoft,
            iconOnly: isNarrow,
          ),
          const SizedBox(width: 8),
          _UpcomingChip(
            label: 'Instagram DM',
            pathD: _kPathInstagram,
            color: const Color(0xFFE1306C),
            badge: 'EXPLORANDO',
            iconOnly: isNarrow,
          ),
        ];

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
              ...chips,
            ],
          ),
        );
      },
    );
  }
}

class _ActiveChip extends StatefulWidget {
  const _ActiveChip({this.iconOnly = false});
  final bool iconOnly;

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
            builder: (_, _) => _brandSvg(
              _kPathWhatsApp,
              KTokens.waGreen.withValues(alpha: _anim.value),
              13,
            ),
          ),
          if (!widget.iconOnly) ...[
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
        ],
      ),
    );
  }
}

class _UpcomingChip extends StatelessWidget {
  const _UpcomingChip({
    required this.label,
    required this.pathD,
    required this.color,
    this.badge = 'PRÓXIMO',
    this.iconOnly = false,
  });
  final String label;
  final String pathD;
  final Color color;
  final String badge;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KTokens.rPill),
        border: Border.all(color: KTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _brandSvg(pathD, color, 13),
          if (!iconOnly) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkSoft),
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
        ],
      ),
    );
  }
}
