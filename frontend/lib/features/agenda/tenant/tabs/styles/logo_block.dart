import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../register/konecta_tokens.dart';

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
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : onUpload,
                  icon: isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_upward_rounded, size: 16),
                  label: Text(isUploading ? 'Subiendo…' : 'Subir imagen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KTokens.ink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: KTokens.border,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KTokens.rSm),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
      child: url != null && url!.startsWith('http')
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          : _placeholder(),
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
