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

/// Indicador «Paso X de Y» + barra de progreso.
class PublicReservarProgressIndicator extends StatelessWidget {
  const PublicReservarProgressIndicator({
    super.key,
    required this.theme,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabel,
  });

  final PublicReservarTheme theme;
  final int currentStep;
  final int totalSteps;
  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Paso $currentStep de $totalSteps',
              style: t.textStyle(
                size: 12,
                weight: FontWeight.w600,
                color: t.primary,
              ),
            ),
            if (stepLabel != null && stepLabel!.isNotEmpty) ...[
              Text(
                ' · ',
                style: t.textStyle(size: 12, color: t.textSub),
              ),
              Expanded(
                child: Text(
                  stepLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textStyle(size: 12, color: t.textSub),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: t.cardBorder,
            color: t.primary,
          ),
        ),
      ],
    );
  }
}

/// Shell de reserva: cabecera de marca + progreso + contenido.
class PublicReservarShell extends StatelessWidget {
  const PublicReservarShell({
    super.key,
    required this.theme,
    required this.brandTitle,
    this.subtitle,
    this.sectionTitle,
    this.sectionTitleInScroll = false,
    this.progressCurrent,
    this.progressTotal,
    this.progressStepLabel,
    required this.child,
    this.onBack,
    this.footer,
    this.maxWidth = 520,
  });

  final PublicReservarTheme theme;
  final String brandTitle;
  final String? subtitle;
  final String? sectionTitle;
  /// Si true, el [sectionTitle] no se fija arriba (va en el scroll del [child]).
  final bool sectionTitleInScroll;
  final int? progressCurrent;
  final int? progressTotal;
  final String? progressStepLabel;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final showFixedStepTitle =
        sectionTitle != null && sectionTitle!.isNotEmpty && !sectionTitleInScroll;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReservarHeader(
                  theme: t,
                  title: brandTitle,
                  subtitle: subtitle,
                  onBack: onBack,
                  progressCurrent: progressCurrent,
                  progressTotal: progressTotal,
                  progressStepLabel: progressStepLabel,
                ),
                if (showFixedStepTitle)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Text(
                      sectionTitle!,
                      style: t.textStyle(size: 22, weight: FontWeight.w700),
                    ),
                  ),
                Expanded(child: child),
                if (footer != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
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

/// Cabecera unificada: tarjeta de marca + barra de progreso.
class _ReservarHeader extends StatelessWidget {
  const _ReservarHeader({
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
    final hasProgress = progressCurrent != null &&
        progressTotal != null &&
        progressTotal! > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    t.primary,
                    Color.lerp(t.primary, Colors.black, 0.12) ?? t.primary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: t.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (onBack != null)
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: Colors.white,
                        ),
                      )
                    else
                      const SizedBox(width: 12),
                    PublicReservarAvatar(
                      nombre: title,
                      logoUrl: t.logoUrl,
                      color: Colors.white,
                      borderColor: Colors.white,
                      size: 52,
                      initialsColor: t.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.textStyle(
                              size: 17,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.textStyle(
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              'Reserva online',
                              style: t.textStyle(
                                size: 11,
                                weight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasProgress) ...[
            const SizedBox(height: 14),
            PublicReservarProgressIndicator(
              theme: t,
              currentStep: progressCurrent!,
              totalSteps: progressTotal!,
              stepLabel: progressStepLabel,
            ),
          ],
        ],
      ),
    );
  }
}

/// Título del paso dentro del scroll.
Widget publicReservarScrollSectionTitle({
  required PublicReservarTheme theme,
  required String title,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      title,
      style: theme.textStyle(size: 22, weight: FontWeight.w700),
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
  });

  final String nombre;
  final Color color;
  final String? logoUrl;
  final double size;
  final Color? borderColor;
  final Color? initialsColor;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(nombre);
    final letterColor = initialsColor ?? color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.95),
        border: Border.all(
          color: borderColor ?? Colors.white,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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

/// Tarjeta de sucursal (Felito: nombre + dirección, ancho completo).
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
      color: Colors.white,
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
}) {
  return Center(
    child: TextButton(
      onPressed: onTap,
      child: Text(
        'Ver o cancelar mis turnos',
        style: theme.textStyle(
          size: 14,
          weight: FontWeight.w600,
          color: theme.primary,
        ),
      ),
    ),
  );
}
