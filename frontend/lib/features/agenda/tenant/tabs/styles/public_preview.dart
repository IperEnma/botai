import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/agenda_media_image.dart';
import '../../../register/konecta_tokens.dart';
import 'brand_style.dart';

/// Mini-landing pública (versión móvil, una columna) que reacciona en vivo a
/// los cambios del [BrandStyle].
class PublicPreview extends StatelessWidget {
  const PublicPreview({
    super.key,
    required this.businessName,
    required this.subtitle,
    required this.style,
  });

  final String businessName;
  final String subtitle;
  final BrandStyle style;

  @override
  Widget build(BuildContext context) {
    final dark = isDark(style.backgroundColor);
    final bg = parseHex(style.backgroundColor);
    final primary = parseHex(style.primaryColor, fallback: KTokens.accent);
    final ink = dark ? Colors.white : const Color(0xFF0F0F10);
    final inkMuted = dark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF6B6B70);
    final inkFaint = dark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF9A978F);
    final surfaceInner =
        dark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final borderInner = dark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0x14000000);
    final accentSoft = dark ? lighten(style.primaryColor, 0.55) : primary;

    TextStyle font(double size,
        {FontWeight? weight, Color? color, bool italic = false}) {
      try {
        return GoogleFonts.getFont(
          style.fontFamily,
          fontSize: size,
          fontWeight: weight,
          color: color ?? ink,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        );
      } catch (_) {
        return TextStyle(
          fontFamily: style.fontFamily,
          fontSize: size,
          fontWeight: weight,
          color: color ?? ink,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderInner),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    businessName,
                    style: font(15, weight: FontWeight.w500, italic: true),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(KTokens.rPill),
                  ),
                  child: Text(
                    'Reservar',
                    style: font(11,
                        weight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // 2. Hero
          _Hero(
            primary: primary,
            logoUrl: style.logoUrl,
            backgroundColor: bg,
            businessName: businessName,
            subtitle: subtitle,
            ink: ink,
            inkMuted: inkMuted,
            font: font,
          ),

          const SizedBox(height: 14),

          // 3. Card reserva
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _BookingCard(
              primary: primary,
              accentSoft: accentSoft,
              surface: surfaceInner,
              border: borderInner,
              ink: ink,
              inkMuted: inkMuted,
              font: font,
            ),
          ),

          const SizedBox(height: 14),

          // 4. Mapa + redes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _MapCard(
              primary: primary,
              dark: dark,
              surface: surfaceInner,
              border: borderInner,
              ink: ink,
              inkMuted: inkMuted,
              font: font,
              businessName: businessName,
              subtitle: subtitle,
            ),
          ),

          const SizedBox(height: 16),

          // 5. Galería
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: _GalleryStrip(
              photos: style.workPhotos,
              dark: dark,
              inkFaint: inkFaint,
              font: font,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({
    required this.primary,
    required this.logoUrl,
    required this.backgroundColor,
    required this.businessName,
    required this.subtitle,
    required this.ink,
    required this.inkMuted,
    required this.font,
  });

  final Color primary;
  final String? logoUrl;
  final Color backgroundColor;
  final String businessName;
  final String subtitle;
  final Color ink;
  final Color inkMuted;
  final TextStyle Function(double, {FontWeight? weight, Color? color, bool italic}) font;

  @override
  Widget build(BuildContext context) {
    final primarySoft = Color.fromARGB(
      0xCC, primary.r.toInt(), primary.g.toInt(), primary.b.toInt(),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, primarySoft],
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: 38,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: backgroundColor, width: 3),
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl != null
                ? AgendaMediaImage(
                    url: logoUrl,
                    fit: BoxFit.cover,
                    width: 54,
                    height: 54,
                    errorWidget: const _LogoPlaceholder(),
                  )
                : const _LogoPlaceholder(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 100, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businessName,
                style: font(18, weight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 12, color: primary),
                  Icon(Icons.star_rounded, size: 12, color: primary),
                  Icon(Icons.star_rounded, size: 12, color: primary),
                  Icon(Icons.star_rounded, size: 12, color: primary),
                  Icon(Icons.star_rounded, size: 12, color: primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '4.9 · 312 · ${subtitle.isNotEmpty ? subtitle : "Negocio"}',
                      style: font(10.5, color: inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _OpenBadge(font: font),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEEEEE),
      alignment: Alignment.center,
      child: Text(
        'an\nimage',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF999999)),
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.font});
  final TextStyle Function(double, {FontWeight? weight, Color? color, bool italic}) font;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF34D399),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'ABIERTO',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: const Color(0xFF0A8C5B),
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Booking card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.primary,
    required this.accentSoft,
    required this.surface,
    required this.border,
    required this.ink,
    required this.inkMuted,
    required this.font,
  });

  final Color primary;
  final Color accentSoft;
  final Color surface;
  final Color border;
  final Color ink;
  final Color inkMuted;
  final TextStyle Function(double, {FontWeight? weight, Color? color, bool italic}) font;

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    const numbers = [2, 3, 4, 5, 6, 7, 8];
    const activeIndex = 3; // J · 5
    const times = ['09:00', '11:00', '15:00', '17:00'];
    const activeTime = 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESERVÁ ONLINE',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              letterSpacing: 1.4,
              color: accentSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elegí día y horario',
            style: font(17, weight: FontWeight.w500, italic: true),
          ),
          const SizedBox(height: 14),

          // Week strip
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        days[i],
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: inkMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: i == activeIndex ? primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${numbers[i]}',
                          style: font(
                            13,
                            weight: i == activeIndex
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: i == activeIndex ? Colors.white : ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (i != activeIndex)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Time chips
          Row(
            children: [
              for (var i = 0; i < times.length; i++) ...[
                Expanded(
                  child: Container(
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == activeTime ? primary : Colors.transparent,
                      border: Border.all(
                        color: i == activeTime ? primary : border,
                      ),
                      borderRadius: BorderRadius.circular(KTokens.rSm),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      times[i],
                      style: font(
                        11.5,
                        color: i == activeTime ? Colors.white : ink,
                        weight: i == activeTime
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // CTA
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(KTokens.rSm),
            ),
            alignment: Alignment.center,
            child: Text(
              'Reservar · Vie 5, 11:00 →',
              style: font(
                13,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map + socials ────────────────────────────────────────────────────────────

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.primary,
    required this.dark,
    required this.surface,
    required this.border,
    required this.ink,
    required this.inkMuted,
    required this.font,
    required this.businessName,
    required this.subtitle,
  });

  final Color primary;
  final bool dark;
  final Color surface;
  final Color border;
  final Color ink;
  final Color inkMuted;
  final TextStyle Function(double, {FontWeight? weight, Color? color, bool italic}) font;
  final String businessName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Map placeholder
          Container(
            height: 110,
            color: dark
                ? const Color(0xFF1C2230)
                : const Color(0xFFE7E4DC),
            alignment: Alignment.center,
            child: Icon(Icons.location_on_rounded, size: 28, color: primary),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$businessName${subtitle.isNotEmpty ? " · ${subtitle.split(",").first.trim()}" : ""}',
                  style: font(13, weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Av. Brasil 2847 · Montevideo',
                  style: font(11.5, color: inkMuted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SocialPill(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
                        ),
                        icon: Icons.camera_alt_rounded),
                    const SizedBox(width: 8),
                    _SocialPill(
                        color: const Color(0xFF25D366),
                        iconText: 'W'),
                    const SizedBox(width: 8),
                    _SocialPill(
                        color: const Color(0xFF0F0F10),
                        iconText: '♪'),
                    const SizedBox(width: 8),
                    _SocialPill(
                        color: const Color(0xFF1877F2),
                        iconText: 'f'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialPill extends StatelessWidget {
  const _SocialPill({this.color, this.gradient, this.icon, this.iconText});
  final Color? color;
  final LinearGradient? gradient;
  final IconData? icon;
  final String? iconText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: 16, color: Colors.white)
          : Text(
              iconText ?? '',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }
}

// ─── Gallery strip ────────────────────────────────────────────────────────────

class _GalleryStrip extends StatelessWidget {
  const _GalleryStrip({
    required this.photos,
    required this.dark,
    required this.inkFaint,
    required this.font,
  });

  final List<String> photos;
  final bool dark;
  final Color inkFaint;
  final TextStyle Function(double, {FontWeight? weight, Color? color, bool italic}) font;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALGUNOS TRABAJOS',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: inkFaint,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        if (photos.isEmpty)
          _EmptyPlaceholders(dark: dark)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const cols = 4;
              const gap = 6.0;
              final cell = (constraints.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final url in photos)
                    _MiniThumb(size: cell, url: url, dark: dark),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _EmptyPlaceholders extends StatelessWidget {
  const _EmptyPlaceholders({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFEEEAF6);
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 4;
        const gap = 6.0;
        final cell = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: cell,
                height: cell,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MiniThumb extends StatelessWidget {
  const _MiniThumb({required this.size, required this.url, required this.dark});
  final double size;
  final String url;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.10)
            : const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.startsWith('http')
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            )
          : const SizedBox.shrink(),
    );
  }
}
