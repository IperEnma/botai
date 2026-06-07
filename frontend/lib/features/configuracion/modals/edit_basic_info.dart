import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/register/konecta_tokens.dart';
import '../business_config.dart';

class EditBasicInfoResult {
  const EditBasicInfoResult({
    required this.nombre,
    this.descripcion,
    this.direccion,
  });
  final String nombre;
  final String? descripcion;
  final String? direccion;
}

class EditBasicInfoModal extends StatefulWidget {
  const EditBasicInfoModal({super.key, required this.config});

  final BusinessConfig config;

  static Future<EditBasicInfoResult?> show(
    BuildContext context,
    BusinessConfig config,
  ) =>
      showDialog<EditBasicInfoResult>(
        context: context,
        builder: (_) => EditBasicInfoModal(config: config),
      );

  @override
  State<EditBasicInfoModal> createState() => _EditBasicInfoModalState();
}

class _EditBasicInfoModalState extends State<EditBasicInfoModal> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _direccionCtrl;
  String? _nombError;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.config.nombre);
    _descripcionCtrl =
        TextEditingController(text: widget.config.descripcion ?? '');
    _direccionCtrl =
        TextEditingController(text: widget.config.direccion ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _nombError = 'El nombre es requerido');
      return;
    }
    Navigator.of(context).pop(
      EditBasicInfoResult(
        nombre: nombre,
        descripcion: _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim().isEmpty
            ? null
            : _direccionCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: KTokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información básica',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: KTokens.ink,
                ),
              ),
              const SizedBox(height: 20),
              _Field(
                label: 'Nombre *',
                controller: _nombreCtrl,
                errorText: _nombError,
                onChanged: (_) {
                  if (_nombError != null) {
                    setState(() => _nombError = null);
                  }
                },
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Descripción',
                controller: _descripcionCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Dirección',
                controller: _direccionCtrl,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostBtn(
                    label: 'Cancelar',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  _SaveBtn(onTap: _submit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(KTokens.rSm),
      borderSide: BorderSide(
        color: errorText != null ? KTokens.errorColor : KTokens.borderStrong,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: KTokens.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 13.5, color: KTokens.ink),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(KTokens.rSm),
              borderSide: BorderSide(
                color: errorText != null ? KTokens.errorColor : KTokens.accent,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: KTokens.surface,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText!, style: KTokens.tError),
        ],
      ],
    );
  }
}

class _GhostBtn extends StatelessWidget {
  const _GhostBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: KTokens.surface,
            borderRadius: BorderRadius.circular(KTokens.rPill),
            border: Border.all(color: KTokens.borderStrong),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: KTokens.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveBtn extends StatelessWidget {
  const _SaveBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: KTokens.ink,
            borderRadius: BorderRadius.circular(KTokens.rPill),
          ),
          child: Center(
            child: Text(
              'Guardar',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
