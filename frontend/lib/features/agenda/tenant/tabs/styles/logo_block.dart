import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/agenda_media_url.dart';
import '../../../register/konecta_tokens.dart';
import '../../../shared/k_button.dart';

class LogoBlock extends StatelessWidget {
  const LogoBlock({
    super.key,
    required this.logoUrl,
    required this.isUploading,
    required this.onUpload,
  });

  final String? logoUrl;
  final bool isUploading;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _LogoCircle(url: logoUrl),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recomendado: cuadrado, mín. 400×400px — se recorta en círculo.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: KTokens.inkSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              if (MediaQuery.sizeOf(context).width >= 700)
                FractionallySizedBox(
                  widthFactor: 0.5,
                  child: KButton.primary(
                    label: 'Subir imagen',
                    icon: Icons.arrow_upward_rounded,
                    expand: true,
                    loading: isUploading,
                    onPressed: onUpload,
                  ),
                )
              else
                KButton.primary(
                  label: 'Subir imagen',
                  icon: Icons.arrow_upward_rounded,
                  loading: isUploading,
                  onPressed: onUpload,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoCircle extends StatelessWidget {
  const _LogoCircle({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KTokens.surface,
        border: Border.all(color: KTokens.borderStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
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
    );
  }

  Widget _placeholder() {
    return Center(
      child: Text(
        'logo\nor browse files',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: KTokens.inkPlaceholder,
          height: 1.35,
        ),
      ),
    );
  }
}
