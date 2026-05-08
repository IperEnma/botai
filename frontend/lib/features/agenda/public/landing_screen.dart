import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tokens
// ─────────────────────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF6366F1);
const _kPrimaryDark = Color(0xFF4F46E5);
const _kPrimaryDeep = Color(0xFF312E81);
const _kAccent = Color(0xFF8B5CF6);
const _kSurface = Color(0xFFF8FAFC);
const _kBorder = Color(0xFFE2E8F0);
const _kText = Color(0xFF0F172A);
const _kTextSub = Color(0xFF64748B);
const _kTextMuted = Color(0xFF94A3B8);
const _kBreakpoint = 800.0;

TextStyle _h(double size,
        {FontWeight w = FontWeight.w700, Color c = _kText}) =>
    GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c);

TextStyle _b(double size,
        {FontWeight w = FontWeight.w400, Color c = _kTextSub}) =>
    GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c);

bool _isWide(BuildContext ctx) =>
    MediaQuery.sizeOf(ctx).width >= _kBreakpoint;

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class PublicLandingScreen extends StatelessWidget {
  const PublicLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 64), // navbar height placeholder
                const _HeroSection(),
                const _StatsStrip(),
                const _BenefitsSection(),
                const _HowItWorksSection(),
                const _CategoriesSection(),
                const _FinalCtaSection(),
                const _Footer(),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: _Navbar()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navbar
// ─────────────────────────────────────────────────────────────────────────────

class _Navbar extends StatelessWidget {
  const _Navbar();

  @override
  Widget build(BuildContext context) {
    final wide = _isWide(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Logo
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kPrimary, _kAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.calendar_month,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text('AgendaKonecta',
                          style: _h(16, w: FontWeight.w800, c: _kText)),
                    ],
                  ),
                ),

                const Spacer(),

                // Nav links (desktop only)
                if (wide) ...[
                  _NavLink(
                      label: 'Cómo funciona',
                      onTap: () {}),
                  _NavLink(
                      label: 'Ver negocios',
                      onTap: () => context.go('/agenda/search')),
                  const SizedBox(width: 8),
                ],

                // CTAs
                if (wide)
                  OutlinedButton(
                    onPressed: () => context.go('/login'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: _kPrimary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 38),
                    ),
                    child: Text('Iniciar sesión',
                        style: _b(13,
                            w: FontWeight.w600, c: _kPrimary)),
                  ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => context.go('/agenda/register'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 38),
                  ),
                  child: Text(
                      wide ? 'Registrá tu negocio' : 'Registrarse',
                      style: _b(13,
                          w: FontWeight.w600, c: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: _kTextSub),
      child: Text(label,
          style: _b(14, w: FontWeight.w500, c: _kTextSub)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final wide = _isWide(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimaryDeep, _kPrimaryDark, _kPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: wide ? 80 : 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: _HeroCopy()),
                    const SizedBox(width: 64),
                    Expanded(flex: 4, child: _PhoneMockup()),
                  ],
                )
              : Column(
                  children: [
                    _HeroCopy(),
                    const SizedBox(height: 48),
                    _PhoneMockup(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wide = _isWide(context);

    return Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome,
                  size: 14, color: Colors.amber),
              const SizedBox(width: 6),
              Text('Plataforma de reservas online',
                  style: _b(12,
                      w: FontWeight.w600, c: Colors.white)),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Headline
        Text(
          'Gestioná tus turnos\nsin esfuerzo',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: wide ? 52 : 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.15,
          ),
        ),

        const SizedBox(height: 20),

        // Subtitle
        Text(
          'Tu negocio disponible las 24 horas. Los clientes reservan solos, vos te enfocás en tu trabajo.',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: _b(17,
              c: Colors.white.withValues(alpha: 0.85)),
        ),

        const SizedBox(height: 36),

        // CTAs
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment:
              wide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            Builder(builder: (ctx) {
              return FilledButton.icon(
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Ver negocios'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _kPrimaryDark,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                onPressed: () => ctx.go('/agenda/search'),
              );
            }),
            Builder(builder: (ctx) {
              return OutlinedButton.icon(
                icon: const Icon(Icons.store_outlined, size: 18),
                label: const Text('Registrá tu negocio'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(
                      color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onPressed: () => ctx.go('/agenda/register'),
              );
            }),
          ],
        ),

        const SizedBox(height: 32),

        // Trust indicators
        Wrap(
          spacing: 20,
          runSpacing: 8,
          alignment:
              wide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _TrustPill(icon: Icons.check_circle_outline,
                label: 'Sin tarjeta de crédito'),
            _TrustPill(
                icon: Icons.bolt_outlined, label: 'Listo en 5 minutos'),
            _TrustPill(
                icon: Icons.lock_outline, label: '100% seguro'),
          ],
        ),
      ],
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15,
            color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 5),
        Text(label,
            style: _b(13,
                w: FontWeight.w500,
                c: Colors.white.withValues(alpha: 0.75))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone mockup
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wide = _isWide(context);

    return Center(
      child: Container(
        width: wide ? 280 : 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 48,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App bar
              Container(
                height: 56,
                color: _kPrimaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Mi Agenda',
                        style: _h(14, c: Colors.white)),
                    const Spacer(),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 15),
                    ),
                  ],
                ),
              ),

              // Week strip
              Container(
                color: _kPrimary.withValues(alpha: 0.05),
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final d in [
                      ('L', false),
                      ('M', false),
                      ('X', true),
                      ('J', false),
                      ('V', false),
                      ('S', false),
                    ])
                      _DayChip(label: d.$1, selected: d.$2),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Time header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Text('Hoy · Mié 12',
                        style:
                            _b(11, w: FontWeight.w600, c: _kTextSub)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('4 turnos',
                          style: _b(10,
                              w: FontWeight.w600, c: _kPrimary)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Booking cards
              _MockBookingCard(
                time: '10:30',
                name: 'María García',
                service: 'Corte + Coloración',
                color: const Color(0xFF10B981),
              ),
              _MockBookingCard(
                time: '11:30',
                name: 'Lucas Pérez',
                service: 'Barba + Fade',
                color: _kPrimary,
              ),
              _MockBookingCard(
                time: '14:00',
                name: 'Sofía Méndez',
                service: 'Manicura gel',
                color: const Color(0xFFF59E0B),
              ),

              const SizedBox(height: 14),

              // CTA inside mockup
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_kPrimaryDark, _kAccent]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('+ Nueva reserva',
                        style: _b(12,
                            w: FontWeight.w700,
                            c: Colors.white)),
                  ),
                ),
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: selected ? _kPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(label,
            style: _b(11,
                w: FontWeight.w700,
                c: selected ? Colors.white : _kTextMuted)),
      ),
    );
  }
}

class _MockBookingCard extends StatelessWidget {
  const _MockBookingCard({
    required this.time,
    required this.name,
    required this.service,
    required this.color,
  });
  final String time;
  final String name;
  final String service;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border(
            left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time,
                  style: _h(12, c: color)),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: _b(11, w: FontWeight.w600, c: _kText),
                    overflow: TextOverflow.ellipsis),
                Text(service,
                    style: _b(10, c: _kTextMuted),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats strip
// ─────────────────────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kPrimaryDeep,
      padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Wrap(
            spacing: 0,
            runSpacing: 24,
            alignment: WrapAlignment.spaceAround,
            children: const [
              _StatItem(value: '+500', label: 'Negocios activos'),
              _StatDivider(),
              _StatItem(value: '+10K', label: 'Reservas mensuales'),
              _StatDivider(),
              _StatItem(value: '24/7', label: 'Disponible siempre'),
              _StatDivider(),
              _StatItem(value: '5 min', label: 'Para configurarlo'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style: _b(13,
                c: Colors.white.withValues(alpha: 0.65))),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    if (!_isWide(context)) return const SizedBox.shrink();
    return Container(
        height: 40,
        width: 1,
        color: Colors.white.withValues(alpha: 0.2));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Benefits
// ─────────────────────────────────────────────────────────────────────────────

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              _SectionLabel('Por qué elegirnos'),
              const SizedBox(height: 12),
              Text('Tu agenda, en piloto automático',
                  style: _h(32),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Olvidate de las llamadas, mensajes y malentendidos.\nTus clientes reservan solos cuando quieren.',
                style: _b(16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 56),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: const [
                  _BenefitCard(
                    icon: Icons.phone_disabled_outlined,
                    title: 'Sin llamadas',
                    desc: 'Los clientes reservan desde su celular, sin interrumpirte.',
                    color: Color(0xFF6366F1),
                  ),
                  _BenefitCard(
                    icon: Icons.access_time_filled_outlined,
                    title: 'Disponible 24/7',
                    desc: 'Tu agenda abierta a cualquier hora, incluso cuando dormís.',
                    color: Color(0xFF8B5CF6),
                  ),
                  _BenefitCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Recordatorios',
                    desc: 'Confirmaciones automáticas para que nadie olvide su turno.',
                    color: Color(0xFF14B8A6),
                  ),
                  _BenefitCard(
                    icon: Icons.bar_chart_outlined,
                    title: 'Todo en un lugar',
                    desc: 'Servicios, equipo, historial y clientes desde un solo panel.',
                    color: Color(0xFFF59E0B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final w = _isWide(context) ? 240.0 : double.infinity;

    return Container(
      width: w,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 18),
          Text(title, style: _h(17)),
          const SizedBox(height: 8),
          Text(desc, style: _b(14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// How it works
// ─────────────────────────────────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              _SectionLabel('Cómo funciona'),
              const SizedBox(height: 12),
              Text('En 3 pasos y listo',
                  style: _h(32), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Sin complicaciones técnicas. En minutos tu negocio ya recibe reservas.',
                  style: _b(16), textAlign: TextAlign.center),
              const SizedBox(height: 56),
              _isWide(context)
                  ? Row(
                      children: [
                        Expanded(
                            child: _StepCard(
                                step: 1,
                                icon: Icons.tune_outlined,
                                title: 'Configurás',
                                desc: 'Cargás tus servicios, horarios y equipo de trabajo en minutos.')),
                        _StepArrow(),
                        Expanded(
                            child: _StepCard(
                                step: 2,
                                icon: Icons.share_outlined,
                                title: 'Compartís',
                                desc: 'Enviás tu link único a clientes o lo ponés en tu Instagram.')),
                        _StepArrow(),
                        Expanded(
                            child: _StepCard(
                                step: 3,
                                icon: Icons.event_available_outlined,
                                title: 'Te reservan',
                                desc: 'Los clientes eligen horario y listo. Vos recibís la notificación.')),
                      ],
                    )
                  : Column(
                      children: [
                        _StepCard(
                            step: 1,
                            icon: Icons.tune_outlined,
                            title: 'Configurás',
                            desc: 'Cargás tus servicios, horarios y equipo de trabajo.'),
                        const SizedBox(height: 16),
                        _StepCard(
                            step: 2,
                            icon: Icons.share_outlined,
                            title: 'Compartís',
                            desc: 'Enviás tu link único a clientes o lo ponés en tu Instagram.'),
                        const SizedBox(height: 16),
                        _StepCard(
                            step: 3,
                            icon: Icons.event_available_outlined,
                            title: 'Te reservan',
                            desc: 'Los clientes eligen horario y listo. Vos recibís la notificación.'),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.desc,
  });
  final int step;
  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kPrimary, _kAccent]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('$step',
                      style: _h(16, c: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: _kPrimary, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: _h(20)),
          const SizedBox(height: 8),
          Text(desc, style: _b(14)),
        ],
      ),
    );
  }
}

class _StepArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Icon(Icons.arrow_forward,
          color: _kPrimary.withValues(alpha: 0.4), size: 28),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories
// ─────────────────────────────────────────────────────────────────────────────

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection();

  static const _cats = [
    (Icons.content_cut, 'Peluquería', Color(0xFF6366F1)),
    (Icons.face_retouching_natural, 'Estética', Color(0xFFEC4899)),
    (Icons.sports_gymnastics, 'Fitness', Color(0xFF14B8A6)),
    (Icons.medical_services_outlined, 'Salud', Color(0xFF3B82F6)),
    (Icons.spa_outlined, 'Spa', Color(0xFF8B5CF6)),
    (Icons.school_outlined, 'Clases', Color(0xFFF59E0B)),
    (Icons.directions_bike_outlined, 'Deporte', Color(0xFF22C55E)),
    (Icons.psychology_outlined, 'Terapia', Color(0xFFEF4444)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              _SectionLabel('Para todos los rubros'),
              const SizedBox(height: 12),
              Text('Tu negocio, tu categoría',
                  style: _h(32), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('De peluquerías a psicólogos. AgendaKonecta se adapta a cualquier tipo de negocio.',
                  style: _b(16), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  for (final cat in _cats)
                    _CatBubble(
                        icon: cat.$1,
                        label: cat.$2,
                        color: cat.$3),
                ],
              ),
              const SizedBox(height: 36),
              Builder(builder: (ctx) {
                return OutlinedButton.icon(
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: const Text('Explorar todos los negocios'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => ctx.go('/agenda/search'),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatBubble extends StatelessWidget {
  const _CatBubble(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: _b(12, w: FontWeight.w600, c: _kText)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Final CTA
// ─────────────────────────────────────────────────────────────────────────────

class _FinalCtaSection extends StatelessWidget {
  const _FinalCtaSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimaryDeep, _kPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('¿Listo para empezar?',
                    style: _b(13,
                        w: FontWeight.w600, c: Colors.white)),
              ),
              const SizedBox(height: 24),
              Text(
                'Automatizá tus reservas\nhoy mismo',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Miles de profesionales ya usan AgendaKonecta.\nTe configuramos en menos de 5 minutos.',
                style: _b(16,
                    c: Colors.white.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Builder(builder: (ctx) {
                return FilledButton.icon(
                  icon: const Icon(Icons.rocket_launch_outlined,
                      size: 20),
                  label: const Text('Registrá tu negocio — Es gratis'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _kPrimaryDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    elevation: 0,
                  ),
                  onPressed: () => ctx.go('/agenda/register'),
                );
              }),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 5; i++)
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Más de 500 negocios ya confían en nosotros',
                style: _b(13,
                    c: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final wide = _isWide(context);

    return Container(
      color: _kText,
      padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _FooterBrand()),
                    const SizedBox(width: 40),
                    Expanded(child: _FooterLinks('Producto', [
                      'Cómo funciona',
                      'Ver negocios',
                      'Registrarse',
                    ])),
                    Expanded(child: _FooterLinks('Soporte', [
                      'Centro de ayuda',
                      'Contacto',
                      'Estado del servicio',
                    ])),
                    Expanded(child: _FooterLinks('Legal', [
                      'Términos de uso',
                      'Privacidad',
                    ])),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _FooterBrand(),
                    const SizedBox(height: 32),
                  ],
                ),

              const SizedBox(height: 40),
              Divider(
                  color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 20),
              Text(
                '© 2025 AgendaKonecta. Todos los derechos reservados.',
                style: _b(12,
                    c: Colors.white.withValues(alpha: 0.4)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kPrimary, _kAccent]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text('AgendaKonecta',
                style: _h(15, c: Colors.white)),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'La plataforma de reservas\nonline más simple.',
          style: _b(13,
              c: Colors.white.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks(this.title, this.links);
  final String title;
  final List<String> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: _h(13, c: Colors.white)),
        const SizedBox(height: 14),
        for (final link in links) ...[
          Text(link,
              style: _b(13,
                  c: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: _kPrimary.withValues(alpha: 0.2)),
      ),
      child: Text(text,
          style: _b(12, w: FontWeight.w700, c: _kPrimary)),
    );
  }
}
