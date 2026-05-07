import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'konecta_tokens.dart';

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
                            const SizedBox(height: 28),
                            // WA confirmation strip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDF7EE),
                                borderRadius:
                                    BorderRadius.circular(KTokens.rMd),
                                border: Border.all(
                                    color: const Color(0xFFA8D5AA)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366)
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        size: 16,
                                        color: Color(0xFF25D366)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Te encontramos por WhatsApp. Podés empezar cuando quieras.',
                                      style: KTokens.tHint.copyWith(
                                          color: const Color(0xFF2D6A30)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 36),
                            // Option cards
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final side = (constraints.maxWidth - 16) / 2;
                                final useRow = constraints.maxWidth > 420;
                                if (useRow) {
                                  return Row(
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
                                          onTap: () =>
                                              context.go('/agenda/search'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: side,
                                        child: _OptionCard(
                                          icon: Icons.storefront_outlined,
                                          iconBg:
                                              const Color(0x1425D366),
                                          iconColor:
                                              const Color(0xFF1A8C40),
                                          title: 'Registrar mi',
                                          titleItalic: 'negocio',
                                          description:
                                              'Registrá tu negocio, gestioná tu agenda y conectá con más clientes.',
                                          onTap: () => context
                                              .go('/agenda/business-register'),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    _OptionCard(
                                      icon: Icons.search_rounded,
                                      iconBg: KTokens.accentSoft,
                                      iconColor: KTokens.accent,
                                      title: 'Buscar',
                                      titleItalic: 'negocios',
                                      description:
                                          'Encontrá profesionales y negocios cerca de vos y agendá tu turno de forma rápida y simple.',
                                      onTap: () =>
                                          context.go('/agenda/search'),
                                    ),
                                    const SizedBox(height: 16),
                                    _OptionCard(
                                      icon: Icons.storefront_outlined,
                                      iconBg: const Color(0x1425D366),
                                      iconColor: const Color(0xFF1A8C40),
                                      title: 'Registrar mi',
                                      titleItalic: 'negocio',
                                      description:
                                          'Registrá tu negocio, gestioná tu agenda y conectá con más clientes.',
                                      onTap: () => context
                                          .go('/agenda/business-register'),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 32),
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
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String titleItalic;
  final String description;
  final VoidCallback onTap;

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: KTokens.surface,
            borderRadius: BorderRadius.circular(16),
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22),
              ),
              const SizedBox(height: 20),
              // Title
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '${widget.title} ',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: KTokens.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: widget.titleItalic,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontStyle: FontStyle.italic,
                      color: KTokens.ink,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              // Description
              Text(
                widget.description,
                style: KTokens.tHint.copyWith(height: 1.55),
              ),
              const SizedBox(height: 20),
              // Arrow
              Text(
                '→',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: KTokens.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
