import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/register/konecta_tokens.dart';

enum ContactKind { whatsapp, email }

class EditContactModal extends StatefulWidget {
  const EditContactModal({
    super.key,
    required this.kind,
    required this.current,
  });

  final ContactKind kind;
  final String? current;

  static Future<String?> show(
    BuildContext context, {
    required ContactKind kind,
    required String? current,
  }) =>
      showDialog<String>(
        context: context,
        builder: (_) => EditContactModal(kind: kind, current: current),
      );

  @override
  State<EditContactModal> createState() => _EditContactModalState();
}

class _EditContactModalState extends State<EditContactModal> {
  late final TextEditingController _ctrl;
  String? _error;

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
        ContactKind.whatsapp => 'Número de WhatsApp',
        ContactKind.email    => 'Email de contacto',
      };

  String get _hint => switch (widget.kind) {
        ContactKind.whatsapp => '+598 99 000 000',
        ContactKind.email    => 'contacto@negocio.com',
      };

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) {
      Navigator.of(context).pop('');
      return;
    }
    if (widget.kind == ContactKind.whatsapp &&
        !RegExp(r'^\+?[0-9\s\-]{7,20}$').hasMatch(v)) {
      setState(() => _error = 'Formato inválido (+598…)');
      return;
    }
    if (widget.kind == ContactKind.email &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      setState(() => _error = 'Email inválido');
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(KTokens.rSm),
      borderSide: BorderSide(
        color: _error != null ? KTokens.errorColor : KTokens.borderStrong,
      ),
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
                keyboardType: widget.kind == ContactKind.email
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
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
                    borderSide: BorderSide(
                      color: _error != null ? KTokens.errorColor : KTokens.accent,
                      width: 1.5,
                    ),
                  ),
                  errorText: _error,
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
                    onTap: _submit,
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
