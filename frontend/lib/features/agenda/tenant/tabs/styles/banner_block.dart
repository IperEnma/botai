import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/agenda_media_url.dart';
import '../../../register/konecta_tokens.dart';
import '../../../shared/agenda_default_banner.dart';
import '../../../shared/k_button.dart';
import '../../../../../core/agenda_media_image.dart';

/// Bloque de subida de imagen de portada (banner) del negocio.
class BannerBlock extends StatelessWidget {
  const BannerBlock({
    super.key,
    required this.bannerUrl,
    required this.primaryColor,
    required this.isUploading,
    required this.onUpload,
    required this.onPresetSelected,
  });

  final String? bannerUrl;
  final String primaryColor;
  final bool isUploading;
  final VoidCallback? onUpload;
  final ValueChanged<String> onPresetSelected;

  bool get _hasUploadedImage => isAgendaMediaUrl(bannerUrl);

  String get _selectedPresetId =>
      AgendaDefaultBanner.effectivePresetId(_hasUploadedImage ? null : bannerUrl);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BannerPreview(
          bannerUrl: bannerUrl,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 14),
        Text(
          'Portadas incluidas',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: KTokens.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Elegí un estilo o subí tu foto. Si no subís imagen, se usa el color principal.',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: KTokens.inkSoft,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in AgendaDefaultBanner.presets)
              _PresetChip(
                preset: preset,
                primaryColor: primaryColor,
                selected: !_hasUploadedImage && _selectedPresetId == preset.id,
                onTap: () => onPresetSelected(preset.id),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Recomendado: horizontal, mín. 1200×400px — se muestra a todo el ancho del perfil.',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: KTokens.inkSoft,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        KButton.primary(
          label: _hasUploadedImage ? 'Cambiar foto' : 'Subir portada',
          icon: Icons.arrow_upward_rounded,
          loading: isUploading,
          onPressed: onUpload,
        ),
      ],
    );
  }
}

class _BannerPreview extends StatelessWidget {
  const _BannerPreview({
    required this.bannerUrl,
    required this.primaryColor,
  });

  final String? bannerUrl;
  final String primaryColor;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width.clamp(320.0, 1200.0);
    final h = w * 6 / 16;
    final hasImage = isAgendaMediaUrl(bannerUrl);

    return AspectRatio(
      aspectRatio: 16 / 6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KTokens.rMd),
          border: Border.all(color: KTokens.borderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? AgendaMediaImage(
                url: bannerUrl,
                fit: BoxFit.cover,
                width: w,
                height: h,
                errorWidget: AgendaDefaultBannerBackground(
                  bannerUrl: bannerUrl,
                  primaryColorHex: primaryColor,
                ),
              )
            : AgendaDefaultBannerBackground(
                bannerUrl: bannerUrl,
                primaryColorHex: primaryColor,
              ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.primaryColor,
    required this.selected,
    required this.onTap,
  });

  final BannerPreset preset;
  final String primaryColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewUrl =
        preset.id == AgendaDefaultBanner.brandId ? null : AgendaDefaultBanner.presetToken(preset.id);

    return Semantics(
      label: preset.label,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KTokens.rSm),
            border: Border.all(
              color: selected ? KTokens.ink : KTokens.borderStrong,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: AgendaDefaultBannerBackground(
                  bannerUrl: previewUrl,
                  primaryColorHex: primaryColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(
                  preset.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? KTokens.ink : KTokens.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
