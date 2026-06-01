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
    this.onBack,
    this.footer,
    this.progressCurrent,
    this.progressTotal,
    this.progressStepLabel,
    this.maxWidth = 520,
  });

  final PublicReservarTheme theme;
  final String brandTitle;
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
                _ReservarAppBar(
                  theme: t,
                  title: brandTitle,
                  onBack: onBack,
                ),
                if (hasProgress)
                  _ReservarStepBar(
                    theme: t,
                    current: progressCurrent!,
                    total: progressTotal!,
                    stepLabel: progressStepLabel,
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

/// Barra superior fija y liviana (estilo app de reservas).
class _ReservarAppBar extends StatelessWidget {
  const _ReservarAppBar({
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
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: t.text),
            )
          else
            const SizedBox(width: 8),
          PublicReservarAvatar(
            nombre: title,
            logoUrl: t.logoUrl,
            color: t.primary,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.textStyle(size: 16, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Segmentos de progreso (checkout / wizard).
class _ReservarStepBar extends StatelessWidget {
  const _ReservarStepBar({
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: List.generate(total, (i) {
              final stepNum = i + 1;
              final isDone = stepNum < current;
              final isCurrent = stepNum == current;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < total - 1 ? 5 : 0),
                  decoration: BoxDecoration(
                    color: isDone || isCurrent
                        ? t.primary
                        : t.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            stepLabel != null && stepLabel!.isNotEmpty
                ? 'Paso $current de $total · $stepLabel'
                : 'Paso $current de $total',
            style: t.textStyle(size: 12, color: t.textSub),
          ),
        ],
      ),
    );
  }
}

/// Intro de marca al inicio del scroll (solo paso 1).
Widget publicReservarScrollBrandIntro({
  required PublicReservarTheme theme,
  required String title,
  String? subtitle,
}) {
  final t = theme;
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PublicReservarAvatar(
              nombre: title,
              logoUrl: t.logoUrl,
              color: t.primary,
              size: 56,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.textStyle(size: 20, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reserva online',
                    style: t.textStyle(
                      size: 13,
                      weight: FontWeight.w600,
                      color: t.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: t.textStyle(size: 14, color: t.textSub, weight: FontWeight.w400),
          ),
        ],
      ],
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
    padding: const EdgeInsets.only(bottom: 16),
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
        color: color.withValues(alpha: 0.1),
        border: Border.all(
          color: borderColor ?? color.withValues(alpha: 0.25),
          width: 2,
        ),
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
