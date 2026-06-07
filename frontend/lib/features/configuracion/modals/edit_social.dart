import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/register/konecta_tokens.dart';
import '../business_config.dart';

class EditSocialModal extends StatefulWidget {
  const EditSocialModal({
    super.key,
    required this.kind,
    required this.current,
  });

  final SocialKind kind;
  final String? current;

  static Future<String?> show(
    BuildContext context, {
    required SocialKind kind,
    required String? current,
  }) =>
      showDialog<String>(
        context: context,
        builder: (_) => EditSocialModal(kind: kind, current: current),
      );

  @override
  State<EditSocialModal> createState() => _EditSocialModalState();
}

class _EditSocialModalState extends State<EditSocialModal> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _title => switch (widget.kind) {
        SocialKind.instagram => 'Instagram',
        SocialKind.tiktok    => 'TikTok',
        SocialKind.facebook  => 'Facebook',
        SocialKind.whatsapp  => 'WhatsApp',
      };

  String get _hint => switch (widget.kind) {
        SocialKind.instagram => '@tu_negocio',
        SocialKind.tiktok    => '@tu_negocio',
        SocialKind.facebook  => 'Nombre de página o URL',
        SocialKind.whatsapp  => '+598 99 000 000',
      };

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(KTokens.rSm),
      borderSide: const BorderSide(color: KTokens.borderStrong),
    );

    return Dialog(
      backgroundColor: KTokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: KTokens.ink,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                autofocus: true,
                style: GoogleFonts.jetBrainsMono(fontSize: 13.5, color: KTokens.ink),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  hintText: _hint,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: KTokens.inkSoft,
                    fontStyle: FontStyle.italic,
                  ),
                  enabledBorder: border,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KTokens.rSm),
                    borderSide:
                        const BorderSide(color: KTokens.accent, width: 1.5),
                  ),
                  filled: true,
                  fillColor: KTokens.surface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Btn(
                    label: 'Cancelar',
                    filled: false,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  _Btn(
                    label: 'Guardar',
                    filled: true,
                    onTap: () =>
                        Navigator.of(context).pop(_ctrl.text.trim()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: filled ? KTokens.ink : KTokens.surface,
            borderRadius: BorderRadius.circular(KTokens.rPill),
            border: filled ? null : Border.all(color: KTokens.borderStrong),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: filled ? Colors.white : KTokens.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
