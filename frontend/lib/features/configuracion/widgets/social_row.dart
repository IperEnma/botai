import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/register/konecta_tokens.dart';
import '../business_config.dart';

class SocialNetworkList extends StatelessWidget {
  const SocialNetworkList({
    super.key,
    required this.redes,
    required this.onEdit,
    required this.onConnect,
  });

  final Map<SocialKind, String?> redes;
  final void Function(SocialKind) onEdit;
  final void Function(SocialKind) onConnect;

  static const _kinds = [
    SocialKind.instagram,
    SocialKind.tiktok,
    SocialKind.facebook,
    SocialKind.whatsapp,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _kinds.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, thickness: 1, color: KTokens.border),
          SocialRow(
            kind: _kinds[i],
            handle: redes[_kinds[i]],
            onEdit: () => onEdit(_kinds[i]),
            onConnect: () => onConnect(_kinds[i]),
          ),
        ],
      ],
    );
  }
}

class SocialRow extends StatelessWidget {
  const SocialRow({
    super.key,
    required this.kind,
    required this.handle,
    required this.onEdit,
    required this.onConnect,
  });

  final SocialKind kind;
  final String? handle;
  final VoidCallback onEdit;
  final VoidCallback onConnect;

  bool get _connected => handle != null && handle!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final actionLabel = _connected ? 'Editar' : '+ Conectar';
    final semanticDesc = _connected
        ? '${_name(kind)}, conectado $handle'
        : '${_name(kind)}, no conectado';

    return Semantics(
      button: true,
      label: semanticDesc,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _SocialIcon(kind: kind),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name(kind),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: KTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _connected ? handle! : _connectHint(kind),
                    style: _connected
                        ? GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: KTokens.inkMuted,
                          )
                        : GoogleFonts.inter(
                            fontSize: 12,
                            color: KTokens.inkSoft,
                            fontStyle: FontStyle.italic,
                          ),
                  ),
                ],
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _connected ? onEdit : onConnect,
                child: Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _connected ? KTokens.inkMuted : KTokens.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _name(SocialKind k) => switch (k) {
        SocialKind.instagram => 'Instagram',
        SocialKind.tiktok    => 'TikTok',
        SocialKind.facebook  => 'Facebook',
        SocialKind.whatsapp  => 'WhatsApp',
      };

  static String _connectHint(SocialKind k) => switch (k) {
        SocialKind.whatsapp => 'Conectar número',
        _                   => 'Conectar perfil',
      };
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.kind});
  final SocialKind kind;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 36,
        height: 36,
        child: _background(kind),
      ),
    );
  }

  Widget _background(SocialKind k) {
    switch (k) {
      case SocialKind.instagram:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFf58529),
                Color(0xFFdd2a7b),
                Color(0xFF8134af),
              ],
            ),
          ),
          child: const Icon(
            Icons.camera_alt_outlined,
            size: 18,
            color: Colors.white,
          ),
        );
      case SocialKind.tiktok:
        return Container(
          color: const Color(0xFF0f0f10),
          child: const Icon(
            Icons.music_note_outlined,
            size: 18,
            color: Colors.white,
          ),
        );
      case SocialKind.facebook:
        return Container(
          color: const Color(0xFF1877f2),
          child: const Icon(
            Icons.facebook_outlined,
            size: 18,
            color: Colors.white,
          ),
        );
      case SocialKind.whatsapp:
        return Container(
          color: const Color(0xFF25D366),
          child: const Icon(
            Icons.chat_bubble_outline,
            size: 18,
            color: Colors.white,
          ),
        );
    }
  }
}
