import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../register/konecta_tokens.dart';

/// Botón unificado del panel admin Konecta.
///
/// Tres variantes cubren ~95% de los casos:
/// - **primary**: acción dura — fondo ink (negro). Ej: *Guardar, Continuar, Subir imagen, Agendar*.
/// - **accent**: flujo principal en wizard/panel — fondo accent (morado).
///   Ej: *Crear servicio →, Agregar N servicios →*.
/// - **secondary**: outline — fondo blanco, borde fino. Ej: *Cancelar, WhatsApp, Atrás*.
///
/// Métricas fijas: alto 38, radius `rSm`, fuente Inter 13 w500, padding 16/0.
/// Si `loading` es true, el contenido se reemplaza por un spinner blanco.
class KButton extends StatelessWidget {
  const KButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.loading = false,
    this.onPressed,
    this.expand = false,
    this.compact = false,
  }) : _variant = _KButtonVariant.primary;

  const KButton.accent({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.loading = false,
    this.onPressed,
    this.expand = false,
    this.compact = false,
  }) : _variant = _KButtonVariant.accent;

  const KButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.loading = false,
    this.onPressed,
    this.expand = false,
    this.compact = false,
  }) : _variant = _KButtonVariant.secondary;

  final String label;
  final IconData? icon;
  final IconData? trailing;
  final bool loading;
  final VoidCallback? onPressed;
  /// Si true, el botón se expande al ancho disponible. Por defecto, ancho intrínseco.
  final bool expand;
  /// Si true, usa geometría compacta (pill 32px) para headers/page actions.
  /// Por defecto, geometría estándar (38px, rSm) para footers/forms.
  final bool compact;
  final _KButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final scheme = _scheme(_variant);

    final fontSize = compact ? 12.0 : 13.0;
    final fontWeight = compact ? FontWeight.w600 : FontWeight.w500;
    final iconSize = compact ? 14.0 : 16.0;
    final height = compact ? 32.0 : 38.0;
    final radius = compact ? KTokens.rPill : KTokens.rSm;
    final hPad = compact ? 14.0 : 16.0;

    final child = loading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.fg,
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize, color: scheme.fg),
                SizedBox(width: compact ? 6 : 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: scheme.fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                Icon(trailing, size: iconSize, color: scheme.fg),
              ],
            ],
          );

    final button = SizedBox(
      height: height,
      child: Material(
        color: disabled ? scheme.disabledBg : scheme.bg,
        shape: RoundedRectangleBorder(
          side: scheme.borderColor != null
              ? BorderSide(color: scheme.borderColor!)
              : BorderSide.none,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Align(
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );

    if (expand) return SizedBox(width: double.infinity, child: button);
    return button;
  }

  _KScheme _scheme(_KButtonVariant v) {
    switch (v) {
      case _KButtonVariant.primary:
        return _KScheme(
          bg: KTokens.ink,
          fg: Colors.white,
          disabledBg: KTokens.border,
          borderColor: null,
        );
      case _KButtonVariant.accent:
        return _KScheme(
          bg: KTokens.accent,
          fg: Colors.white,
          disabledBg: KTokens.border,
          borderColor: null,
        );
      case _KButtonVariant.secondary:
        return _KScheme(
          bg: KTokens.surface,
          fg: KTokens.ink,
          disabledBg: KTokens.surface,
          borderColor: KTokens.borderStrong,
        );
    }
  }
}

enum _KButtonVariant { primary, accent, secondary }

class _KScheme {
  final Color bg;
  final Color fg;
  final Color disabledBg;
  final Color? borderColor;
  const _KScheme({
    required this.bg,
    required this.fg,
    required this.disabledBg,
    required this.borderColor,
  });
}
