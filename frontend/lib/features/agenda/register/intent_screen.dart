import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'konecta_tokens.dart';

const _kWaSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z" fill="white"/>
</svg>''';

class IntentScreen extends StatelessWidget {
  const IntentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KTokens.bg,
      body: Stack(
        children: [
          const _BackgroundCards(),
          SafeArea(
            child: Column(
              children: [
                // ── Nav ─────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 24, 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go('/agenda'),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: KTokens.borderStrong),
                          ),
                          child: const Icon(Icons.arrow_back,
                              size: 15, color: KTokens.ink),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'konecta',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: KTokens.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'CREAR CUENTA',
                        style: KTokens.tEyebrow
                            .copyWith(letterSpacing: 1.4, color: KTokens.ink),
                      ),
                    ],
                  ),
                ),
                // ── Content ──────────────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Eyebrow
                            Text(
                              'BIENVENIDO',
                              textAlign: TextAlign.center,
                              style: KTokens.tEyebrow.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 2.5,
                                  color: KTokens.inkSoft),
                            ),
                            const SizedBox(height: 10),
                            // Headline
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(children: [
                                TextSpan(
                                  text: '¿Qué querés ',
                                  style: GoogleFonts.inter(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: KTokens.ink,
                                    letterSpacing: -1,
                                    height: 1.1,
                                  ),
                                ),
                                TextSpan(
                                  text: 'hacer?',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 38,
                                    fontStyle: FontStyle.italic,
                                    color: KTokens.accent,
                                    height: 1.1,
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 14),
                            // Subtitle
                            Text(
                              'Estás listo para comenzar. Elegí la opción que\nmejor se adapte a vos y empezá a usar Konecta.',
                              textAlign: TextAlign.center,
                              style: KTokens.tHint.copyWith(height: 1.6),
                            ),
                            // WA note (desktop only) + cards
                            LayoutBuilder(
                              builder: (_, constraints) {
                                final isWide = constraints.maxWidth > 420;
                                final side = (constraints.maxWidth - 16) / 2;
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // ── WA note ──────────────────────────
                                    SizedBox(height: isWide ? 20 : 32),
                                    if (isWide)
                                      Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 1),
                                              child: SvgPicture.string(
                                                _kWaSvg,
                                                width: 13,
                                                height: 13,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                  Color(0xFF25D366),
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                            Flexible(
                                              child: RichText(
                                                text: TextSpan(
                                                  style:
                                                      KTokens.tHint.copyWith(
                                                    fontSize: 12.5,
                                                    color: KTokens.inkSoft,
                                                    height: 1.55,
                                                  ),
                                                  children: const [
                                                    TextSpan(
                                                      text:
                                                          'Te enviamos tu contraseña por WhatsApp. ',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          'Puedes cambiarla cuando quieras desde configuración.',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: KTokens.tHint.copyWith(
                                            fontSize: 12.5,
                                            color: KTokens.inkSoft,
                                            height: 1.55,
                                          ),
                                          children: const [
                                            TextSpan(
                                              text:
                                                  'Te enviamos tu contraseña por WhatsApp. ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            TextSpan(
                                              text:
                                                  'Puedes cambiarla cuando quieras desde configuración.',
                                            ),
                                          ],
                                        ),
                                      ),
                                    SizedBox(height: isWide ? 28 : 32),
                                    // ── Cards ────────────────────────────
                                    if (isWide)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: side,
                                            child: _OptionCard(
                                              icon: Icons.search_rounded,
                                              iconBg: KTokens.accentSoft,
                                              iconColor: KTokens.accent,
                                              title: 'Buscar',
                                              titleItalic: 'negocios',
                                              description:
                                                  'Encontrá profesionales y negocios cerca de vos y agendá tu turno de forma rápida y simple.',
                                              targetRoute: '/agenda/search',
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          SizedBox(
                                            width: side,
                                            child: _OptionCard(
                                              icon: Icons.storefront_outlined,
                                              iconBg: const Color(0x1425D366),
                                              iconColor:
                                                  const Color(0xFF1A8C40),
                                              title: 'Registrar mi',
                                              titleItalic: 'negocio',
                                              description:
                                                  'Registrá tu negocio, gestioná tu agenda y conectá con más clientes.',
                                              targetRoute:
                                                  '/agenda/business-register',
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Column(
                                        children: [
                                          _OptionCard(
                                            icon: Icons.search_rounded,
                                            iconBg: KTokens.accentSoft,
                                            iconColor: KTokens.accent,
                                            title: 'Buscar',
                                            titleItalic: 'negocios',
                                            description: '',
                                            compact: true,
                                            targetRoute: '/agenda/search',
                                          ),
                                          const SizedBox(height: 12),
                                          _OptionCard(
                                            icon: Icons.storefront_outlined,
                                            iconBg: const Color(0x1425D366),
                                            iconColor:
                                                const Color(0xFF1A8C40),
                                            title: 'Registrar mi',
                                            titleItalic: 'negocio',
                                            description: '',
                                            compact: true,
                                            targetRoute:
                                                '/agenda/business-register',
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 32),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Option card ───────────────────────────────────────────────────────────────

class _OptionCard extends StatefulWidget {
  const _OptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.titleItalic,
    required this.description,
    required this.targetRoute,
    this.compact = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String titleItalic;
  final String description;
  final String targetRoute;
  final bool compact;

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _hovered = false;

  BoxDecoration get _decoration => BoxDecoration(
        color: KTokens.surface,
        borderRadius: BorderRadius.circular(widget.compact ? 16 : 20),
        border: Border.all(
          color: _hovered ? KTokens.accent : KTokens.borderStrong,
          width: _hovered ? 1.5 : 1,
        ),
        boxShadow: _hovered
            ? [
                BoxShadow(
                  color: KTokens.accent.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.targetRoute),
        behavior: HitTestBehavior.opaque,
        child: widget.compact
            ? _buildCompact()
            : _buildFull(),
      ),
    );
  }

  // ── Compact (mobile): icon + title + chevron, horizontal ─────────────────

  Widget _buildCompact() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: _decoration,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: widget.iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '${widget.title} ',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: KTokens.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                TextSpan(
                  text: widget.titleItalic,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: KTokens.ink,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: _hovered ? KTokens.accent : KTokens.inkMuted,
          ),
        ],
      ),
    );
  }

  // ── Full (desktop): vertical card with description ────────────────────────

  Widget _buildFull() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(30),
      decoration: _decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: widget.iconBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 28),
          ),
          const SizedBox(height: 25),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: '${widget.title} ',
                style: GoogleFonts.inter(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  color: KTokens.ink,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: widget.titleItalic,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                  color: KTokens.ink,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 13),
          Text(
            widget.description,
            style: KTokens.tHint.copyWith(height: 1.55),
          ),
          const SizedBox(height: 25),
          Text(
            '→',
            style: GoogleFonts.inter(
              fontSize: 23,
              color: KTokens.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background decoration (same as register screen) ───────────────────────────

class _BackgroundCards extends StatelessWidget {
  const _BackgroundCards();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(children: [
          _card(left: -w * 0.12, top: h * 0.13, width: w * 0.30, height: 72),
          _card(left: -w * 0.06, top: h * 0.28, width: w * 0.34, height: 56),
          _card(left: -w * 0.14, top: h * 0.44, width: w * 0.28, height: 72),
          _card(left: -w * 0.08, top: h * 0.60, width: w * 0.32, height: 56),
          _card(right: -w * 0.10, top: h * 0.10, width: w * 0.32, height: 72),
          _card(right: -w * 0.06, top: h * 0.26, width: w * 0.30, height: 56),
          _card(right: -w * 0.12, top: h * 0.42, width: w * 0.34, height: 72),
          _card(right: -w * 0.08, top: h * 0.58, width: w * 0.28, height: 56),
          _card(left: w * 0.06,  bottom: h * 0.06, width: w * 0.26, height: 44),
          _card(right: w * 0.06, bottom: h * 0.03, width: w * 0.24, height: 44),
        ]);
      },
    );
  }

  Widget _card({
    double? left, double? right, double? top, double? bottom,
    required double width, required double height,
  }) {
    return Positioned(
      left: left, right: right, top: top, bottom: bottom,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: KTokens.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KTokens.border),
        ),
      ),
    );
  }
}
