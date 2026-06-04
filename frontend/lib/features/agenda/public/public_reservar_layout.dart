import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema y layout compartido para `/reservar` (marca → sucursal → turno).
class PublicReservarTheme {
  PublicReservarTheme({
    required this.primary,
    required this.background,
    required this.dark,
    this.fontFamily = 'Roboto',
    this.logoUrl,
  });

  final Color primary;
  final Color background;
  final bool dark;
  final String fontFamily;
  final String? logoUrl;

  Color get text => dark ? Colors.white : const Color(0xFF0F172A);
  Color get textSub => dark ? Colors.white70 : const Color(0xFF64748B);
  Color get cardFill =>
      dark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF8FAFC);
  Color get cardBorder =>
      dark ? Colors.white12 : const Color(0xFFE2E8F0);
  Color get surface =>
      dark ? const Color(0xFF1E293B) : Colors.white;

  Color get primarySoft => primary.withValues(alpha: 0.12);

  List<Color> get primaryGradient => [
        primary,
        Color.lerp(primary, const Color(0xFF8B5CF6), 0.35) ?? primary,
      ];

  static PublicReservarTheme fromHex({
    String? colorPrimario,
    String? colorFondo,
    String? fontFamily,
    String? logoUrl,
  }) {
    return PublicReservarTheme(
      primary: _colorFromHex(colorPrimario, const Color(0xFF6366F1)),
      background: _colorFromHex(colorFondo, Colors.white),
      dark: _colorFromHex(colorFondo, Colors.white).computeLuminance() < 0.4,
      fontFamily: fontFamily ?? 'Roboto',
      logoUrl: logoUrl,
    );
  }

  static Color _colorFromHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final val = int.tryParse('FF${hex.replaceAll('#', '')}', radix: 16);
    return val != null ? Color(val) : fallback;
  }

  TextStyle textStyle({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) {
    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
      );
    }
  }
}

/// Shell de reserva: barra superior + pasos + contenido en scroll.
class PublicReservarShell extends StatelessWidget {
  const PublicReservarShell({
    super.key,
    required this.theme,
    required this.brandTitle,
    required this.child,
    this.brandSubtitle,
    this.onBack,
    this.footer,
    this.progressCurrent,
    this.progressTotal,
    this.progressStepLabel,
    this.maxWidth = 520,
  });

  final PublicReservarTheme theme;
  final String brandTitle;
  final String? brandSubtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;
  final int? progressCurrent;
  final int? progressTotal;
  final String? progressStepLabel;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final hasProgress = progressCurrent != null &&
        progressTotal != null &&
        progressTotal! > 0;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReservarHeroHeader(
                  theme: t,
                  title: brandTitle,
                  subtitle: brandSubtitle,
                  onBack: onBack,
                  progressCurrent: hasProgress ? progressCurrent : null,
                  progressTotal: hasProgress ? progressTotal : null,
                  progressStepLabel: progressStepLabel,
                ),
                Expanded(child: child),
                if (footer != null)
                  Container(
                    decoration: BoxDecoration(
                      color: t.surface,
                      border: Border(top: BorderSide(color: t.cardBorder)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: footer!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cabecera con identidad de marca + wizard de pasos numerados.
/// Icono del paso del wizard (1–6).
IconData publicReservarStepIcon(int step) {
  switch (step) {
    case 1:
      return Icons.spa_outlined;
    case 2:
      return Icons.person_outline_rounded;
    case 3:
      return Icons.calendar_month_outlined;
    case 4:
      return Icons.schedule_rounded;
    case 5:
      return Icons.fact_check_outlined;
    case 6:
      return Icons.badge_outlined;
    default:
      return Icons.event_available_outlined;
  }
}

class _ReservarHeroHeader extends StatelessWidget {
  const _ReservarHeroHeader({
    required this.theme,
    required this.title,
    this.subtitle,
    this.onBack,
    this.progressCurrent,
    this.progressTotal,
    this.progressStepLabel,
  });

  final PublicReservarTheme theme;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final int? progressCurrent;
  final int? progressTotal;
  final String? progressStepLabel;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final hasProgress =
        progressCurrent != null && progressTotal != null && progressTotal! > 0;

    final subtitleText = subtitle?.trim();
    final showSubtitle =
        subtitleText != null && subtitleText.isNotEmpty && !hasProgress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.cardBorder),
          boxShadow: [
            BoxShadow(
              color: t.primary.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 88,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: t.primaryGradient,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -24,
                    top: -28,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 8,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipPath(
                      clipper: _HeroWaveClipper(),
                      child: Container(
                        height: 22,
                        color: t.surface,
                      ),
                    ),
                  ),
                  if (onBack != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onBack,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -34),
              child: Column(
                children: [
                  PublicReservarAvatar(
                    nombre: title,
                    logoUrl: t.logoUrl,
                    color: t.primary,
                    borderColor: t.surface,
                    size: 64,
                    initialsColor: t.primary,
                    elevated: true,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.textStyle(size: 19, weight: FontWeight.w700),
                    ),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        subtitleText,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.textStyle(size: 13, color: t.textSub),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          t.primarySoft,
                          t.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: t.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_rounded,
                            size: 15, color: t.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Reserva online',
                          style: t.textStyle(
                            size: 12,
                            weight: FontWeight.w600,
                            color: t.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hasProgress) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _BookingProgressPanel(
                  theme: t,
                  current: progressCurrent!,
                  total: progressTotal!,
                  stepLabel: progressStepLabel,
                ),
              ),
            ] else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _HeroWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.35);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.15,
      size.width,
      size.height * 0.35,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Barra segmentada + tarjeta del paso actual (más legible que 6 círculos).
class _BookingProgressPanel extends StatelessWidget {
  const _BookingProgressPanel({
    required this.theme,
    required this.current,
    required this.total,
    this.stepLabel,
  });

  final PublicReservarTheme theme;
  final int current;
  final int total;
  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final label = stepLabel?.trim();
    final stepTitle =
        label != null && label.isNotEmpty ? label : 'Paso $current';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(total, (i) {
            final step = i + 1;
            final done = step < current;
            final active = step == current;
            return Expanded(
              child: Container(
                height: active ? 7 : 5,
                margin: EdgeInsets.only(right: i < total - 1 ? 5 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: active
                      ? LinearGradient(colors: t.primaryGradient)
                      : null,
                  color: active
                      ? null
                      : (done
                          ? t.primary.withValues(alpha: 0.55)
                          : t.cardFill),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: t.primary.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                t.primarySoft,
                t.primary.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: t.primaryGradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: t.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  publicReservarStepIcon(current),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso $current de $total',
                      style: t.textStyle(
                        size: 11,
                        weight: FontWeight.w600,
                        color: t.textSub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stepTitle,
                      style: t.textStyle(
                        size: 15,
                        weight: FontWeight.w700,
                        color: t.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Descripción del negocio en scroll (solo paso 1).
Widget publicReservarScrollBrandIntro({
  required PublicReservarTheme theme,
  String? subtitle,
}) {
  if (subtitle == null || subtitle.isEmpty) {
    return const SizedBox.shrink();
  }
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        subtitle,
        style: theme.textStyle(size: 14, color: theme.text),
      ),
    ),
  );
}

/// Título del paso dentro del scroll.
Widget publicReservarScrollSectionTitle({
  required PublicReservarTheme theme,
  required String title,
  String? subtitle,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textStyle(size: 24, weight: FontWeight.w700),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textStyle(size: 14, color: theme.textSub),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class PublicReservarAvatar extends StatelessWidget {
  const PublicReservarAvatar({
    super.key,
    required this.nombre,
    required this.color,
    this.logoUrl,
    this.size = 72,
    this.borderColor,
    this.initialsColor,
    this.elevated = false,
  });

  final String nombre;
  final Color color;
  final String? logoUrl;
  final double size;
  final Color? borderColor;
  final Color? initialsColor;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(nombre);
    final letterColor = initialsColor ?? color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: borderColor ?? color.withValues(alpha: 0.25),
          width: elevated ? 3 : 2,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl!.startsWith('http')
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initialsWidget(initials, letterColor),
            )
          : _initialsWidget(initials, letterColor),
    );
  }

  Widget _initialsWidget(String initials, Color letterColor) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: letterColor,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static String _initials(String nombre) {
    final words = nombre.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length.clamp(1, 2)).toUpperCase();
  }
}

/// Tarjeta de sucursal (nombre + dirección).
class PublicBranchTile extends StatelessWidget {
  const PublicBranchTile({
    super.key,
    required this.nombre,
    this.direccion,
    required this.theme,
    required this.onTap,
  });

  final String nombre;
  final String? direccion;
  final PublicReservarTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: t.textStyle(
                        size: 16,
                        weight: FontWeight.w600,
                      ),
                    ),
                    if (direccion != null && direccion!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        direccion!,
                        style: t.textStyle(size: 14, color: t.textSub),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

Widget publicReservarFooterLink({
  required PublicReservarTheme theme,
  required VoidCallback onTap,
  String label = 'Ver o cancelar mis turnos',
}) {
  return Center(
    child: TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: theme.textStyle(
          size: 14,
          weight: FontWeight.w600,
          color: theme.primary,
        ),
      ),
    ),
  );
}
