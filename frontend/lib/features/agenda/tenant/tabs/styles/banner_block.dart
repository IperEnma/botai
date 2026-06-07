import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/agenda_media_url.dart';
import '../../../register/konecta_tokens.dart';
import '../../../shared/k_button.dart';

/// Bloque de subida de imagen de portada (banner) del negocio.
/// Mismo patrón que [LogoBlock] pero con preview rectangular (16:6).
class BannerBlock extends StatelessWidget {
  const BannerBlock({
    super.key,
    required this.bannerUrl,
    required this.isUploading,
    required this.onUpload,
  });

  final String? bannerUrl;
  final bool isUploading;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BannerPreview(url: bannerUrl),
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
          label: 'Subir portada',
          icon: Icons.arrow_upward_rounded,
          loading: isUploading,
          onPressed: onUpload,
        ),
      ],
    );
  }
}

class _BannerPreview extends StatelessWidget {
  const _BannerPreview({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 6,
      child: Container(
        decoration: BoxDecoration(
          color: KTokens.surface,
          borderRadius: BorderRadius.circular(KTokens.rMd),
          border: Border.all(color: KTokens.borderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: () {
          final resolved = resolveAgendaMediaUrl(url);
          return resolved != null
              ? Image.network(
                  resolved,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholder(),
                )
              : _placeholder();
        }(),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined,
              size: 28, color: KTokens.inkPlaceholder),
          const SizedBox(height: 6),
          Text(
            'Sin portada',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: KTokens.inkPlaceholder,
            ),
          ),
        ],
      ),
    );
  }
}
