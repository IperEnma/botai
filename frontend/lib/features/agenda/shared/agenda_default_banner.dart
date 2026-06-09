import 'package:flutter/material.dart';

import '../../../core/agenda_media_url.dart';
import '../tenant/tabs/styles/brand_style.dart';

/// Portadas por defecto cuando el negocio no subió imagen propia.
///
/// Se persisten en [Business.bannerUrl] como `banner-preset:<id>`.
/// `null` / vacío ⇒ gradiente automático del color primario del negocio.
class AgendaDefaultBanner {
  AgendaDefaultBanner._();

  static const brandId = 'brand';

  static const List<BannerPreset> presets = [
    BannerPreset(
      id: brandId,
      label: 'Tu color',
      description: 'Gradiente del color principal',
    ),
    BannerPreset(
      id: 'dusk',
      label: 'Noche',
      colors: [Color(0xFF3B2F63), Color(0xFF1A1A2E)],
    ),
    BannerPreset(
      id: 'ocean',
      label: 'Océano',
      colors: [Color(0xFF0D9488), Color(0xFF155E75)],
    ),
    BannerPreset(
      id: 'warm',
      label: 'Cálido',
      colors: [Color(0xFFEA580C), Color(0xFF9A3412)],
    ),
    BannerPreset(
      id: 'blush',
      label: 'Rosa',
      colors: [Color(0xFFDB2777), Color(0xFF831843)],
    ),
    BannerPreset(
      id: 'slate',
      label: 'Gris',
      colors: [Color(0xFF64748B), Color(0xFF1E293B)],
    ),
  ];

  static bool isPresetToken(String? raw) => isAgendaBannerPreset(raw);

  static String presetToken(String id) => '$kAgendaBannerPresetPrefix$id';

  static String? presetIdFromToken(String? raw) {
    if (!isPresetToken(raw)) return null;
    return raw!.trim().substring(kAgendaBannerPresetPrefix.length);
  }

  static String? normalizeStoredValue(String? raw) => resolveBusinessBannerUrl(raw);

  static String effectivePresetId(String? bannerUrl) {
    return presetIdFromToken(bannerUrl) ?? brandId;
  }

  static BoxDecoration decoration({
    required String? bannerUrl,
    String? primaryColorHex,
  }) {
    final presetId = effectivePresetId(bannerUrl);
    final preset = presets.firstWhere(
      (p) => p.id == presetId,
      orElse: () => presets.first,
    );

    if (preset.id == brandId) {
      final base = parseHex(primaryColorHex ?? '#3B2F63', fallback: const Color(0xFF3B2F63));
      final dark = Color.lerp(base, Colors.black, 0.45) ?? base;
      final light = Color.lerp(base, Colors.white, 0.12) ?? base;
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, base, dark],
          stops: const [0, 0.45, 1],
        ),
      );
    }

    final colors = preset.colors!;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
    );
  }
}

class BannerPreset {
  const BannerPreset({
    required this.id,
    required this.label,
    this.description,
    this.colors,
  });

  final String id;
  final String label;
  final String? description;
  final List<Color>? colors;
}

/// Fondo de portada por defecto (sin imagen subida).
class AgendaDefaultBannerBackground extends StatelessWidget {
  const AgendaDefaultBannerBackground({
    super.key,
    required this.bannerUrl,
    this.primaryColorHex,
  });

  final String? bannerUrl;
  final String? primaryColorHex;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AgendaDefaultBanner.decoration(
        bannerUrl: bannerUrl,
        primaryColorHex: primaryColorHex,
      ),
      child: const SizedBox.expand(),
    );
  }
}
