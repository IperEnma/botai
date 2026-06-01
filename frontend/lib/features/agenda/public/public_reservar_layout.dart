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

/// Cabecera completa (landing / primer paso) vs compacta (más espacio al scroll).
enum PublicReservarHeaderStyle { full, compact }

/// Indicador «Paso X de Y» + barra de progreso (reserva pública).
class PublicReservarProgressIndicator extends StatelessWidget {
  const PublicReservarProgressIndicator({
    super.key,
    required this.theme,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabel,
    this.compact = false,
  });

  final PublicReservarTheme theme;
  /// 1-based (ej. 3 de 6).
  final int currentStep;
  final int totalSteps;
  final String? stepLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);
    final hPad = compact ? 16.0 : 24.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, compact ? 4 : 8, hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Paso $currentStep de $totalSteps',
                style: t.textStyle(
                  size: compact ? 12 : 13,
                  weight: FontWeight.w600,
                  color: t.primary,
                ),
              ),
              if (stepLabel != null && stepLabel!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stepLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textStyle(size: compact ? 12 : 13, color: t.textSub),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: compact ? 6 : 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: compact ? 4 : 6,
              backgroundColor: t.cardBorder,
              color: t.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shell Felito: franja de color, avatar, título, badge «Reserva online», contenido.
class PublicReservarShell extends StatelessWidget {
  const PublicReservarShell({
    super.key,
    required this.theme,
    required this.brandTitle,
    this.subtitle,
    this.sectionTitle,
    this.headerStyle = PublicReservarHeaderStyle.full,
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
  /// Título del paso; en modo [PublicReservarHeaderStyle.compact] conviene ponerlo dentro del scroll del [child].
  final String? sectionTitle;
  final PublicReservarHeaderStyle headerStyle;
  final int? progressCurrent;
  final int? progressTotal;
  final String? progressStepLabel;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;
  final double maxWidth;

  bool get _compact => headerStyle == PublicReservarHeaderStyle.compact;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_compact)
                  _CompactBrandHeader(
                    theme: t,
                    title: brandTitle,
                    onBack: onBack,
                  )
                else ...[
                  if (onBack != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onBack,
                          icon: Icon(Icons.arrow_back_ios_new,
                              size: 20, color: t.text),
                        ),
                      ),
                    ),
                  _BrandBlock(theme: t, title: brandTitle, subtitle: subtitle),
                ],
                if (progressCurrent != null &&
                    progressTotal != null &&
                    progressTotal! > 0)
                  PublicReservarProgressIndicator(
                    theme: t,
                    currentStep: progressCurrent!,
                    totalSteps: progressTotal!,
                    stepLabel: progressStepLabel,
                    compact: _compact,
                  ),
                if (!_compact && sectionTitle != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Text(
                      sectionTitle!,
                      style: t.textStyle(
                        size: 22,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ] else if (!_compact)
                  const SizedBox(height: 8),
                Expanded(child: child),
                if (footer != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      4,
                      24,
                      _compact ? 8 : 12,
                    ),
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

/// Cabecera reducida: atrás + logo + nombre (pasos con scroll).
class _CompactBrandHeader extends StatelessWidget {
  const _CompactBrandHeader({
    required this.theme,
    required this.title,
    this.onBack,
  });

  final PublicReservarTheme theme;
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Column(
      children: [
        Container(height: 3, width: double.infinity, color: t.primary),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 16, 4),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back_ios_new, size: 18, color: t.text),
                )
              else
                const SizedBox(width: 8),
              PublicReservarAvatar(
                nombre: title,
                logoUrl: t.logoUrl,
                color: t.primary,
                borderColor: t.background,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.textStyle(size: 16, weight: FontWeight.w700),
                    ),
                    Text(
                      'Reserva online',
                      style: t.textStyle(size: 11, color: t.textSub),
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

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({
    required this.theme,
    required this.title,
    this.subtitle,
  });

  final PublicReservarTheme theme;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 48,
          color: t.primary,
        ),
        Transform.translate(
          offset: const Offset(0, -28),
          child: Column(
            children: [
              PublicReservarAvatar(
                nombre: title,
                logoUrl: t.logoUrl,
                color: t.primary,
                borderColor: t.background,
                size: 56,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: t.textStyle(size: 20, weight: FontWeight.w700),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.textStyle(size: 13, color: t.textSub),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Reserva online',
                  style: t.textStyle(
                    size: 11,
                    weight: FontWeight.w600,
                    color: t.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Título del paso dentro del scroll (modo compacto).
Widget publicReservarScrollSectionTitle({
  required PublicReservarTheme theme,
  required String title,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: theme.textStyle(size: 20, weight: FontWeight.w700),
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
  });

  final String nombre;
  final Color color;
  final String? logoUrl;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(nombre);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(
          color: borderColor ?? color.withValues(alpha: 0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl!.startsWith('http')
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initialsWidget(initials),
            )
          : _initialsWidget(initials),
    );
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontSize: size * 0.32,
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
