import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/register/konecta_tokens.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({
    super.key,
    required this.whatsapp,
    required this.email,
    required this.onEditWhatsapp,
    required this.onEditEmail,
  });

  final String? whatsapp;
  final String? email;
  final VoidCallback onEditWhatsapp;
  final VoidCallback onEditEmail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 460;
      if (narrow) {
        return Column(
          children: [
            ContactTile.whatsapp(
              value: whatsapp,
              onAction: onEditWhatsapp,
            ),
            const SizedBox(height: 10),
            ContactTile.email(
              value: email,
              onAction: onEditEmail,
            ),
          ],
        );
      }
      return Row(
        children: [
          Expanded(
            child: ContactTile.whatsapp(
              value: whatsapp,
              onAction: onEditWhatsapp,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ContactTile.email(
              value: email,
              onAction: onEditEmail,
            ),
          ),
        ],
      );
    });
  }
}

enum _ContactKind { whatsapp, email }

class ContactTile extends StatelessWidget {
  const ContactTile._({
    required this.kind,
    required this.value,
    required this.onAction,
  });

  factory ContactTile.whatsapp({
    required String? value,
    required VoidCallback onAction,
  }) =>
      ContactTile._(
        kind: _ContactKind.whatsapp,
        value: value,
        onAction: onAction,
      );

  factory ContactTile.email({
    required String? value,
    required VoidCallback onAction,
  }) =>
      ContactTile._(
        kind: _ContactKind.email,
        value: value,
        onAction: onAction,
      );

  // ignore: library_private_types_in_public_api
  final _ContactKind kind;
  final String? value;
  final VoidCallback onAction;

  bool get _hasValue => value != null && value!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasValue) {
      return _FilledTile(kind: kind, value: value!, onEdit: onAction);
    }
    return _EmptyTile(kind: kind, onAdd: onAction);
  }
}

class _FilledTile extends StatelessWidget {
  const _FilledTile({
    required this.kind,
    required this.value,
    required this.onEdit,
  });

  final _ContactKind kind;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: KTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KTokens.borderStrong),
      ),
      child: Row(
        children: [
          _KindIcon(kind: kind, filled: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(kind),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: KTokens.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    color: KTokens.inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onEdit,
              child: Text(
                'Editar',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: KTokens.inkMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.kind, required this.onAdd});
  final _ContactKind kind;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: KTokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: KTokens.borderStrong,
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              _KindIcon(kind: kind, filled: false),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agregar ${_title(kind)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: KTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _emptyHint(kind),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: KTokens.inkSoft,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind, required this.filled});
  final _ContactKind kind;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bgColor) = switch (kind) {
      _ContactKind.whatsapp => (
          Icons.phone_outlined,
          KTokens.waGreenText,
          KTokens.waGreenSoft,
        ),
      _ContactKind.email => (
          Icons.alternate_email_outlined,
          KTokens.accent,
          KTokens.accentSoft,
        ),
    };

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: filled ? bgColor : KTokens.bg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

String _title(_ContactKind k) => switch (k) {
      _ContactKind.whatsapp => 'WhatsApp',
      _ContactKind.email    => 'Email',
    };

String _emptyHint(_ContactKind k) => switch (k) {
      _ContactKind.whatsapp => 'Sin número de contacto',
      _ContactKind.email    => 'Sin email de contacto',
    };
