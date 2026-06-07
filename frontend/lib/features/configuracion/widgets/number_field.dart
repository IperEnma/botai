import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/register/konecta_tokens.dart';

class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.suffix,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.required = false,
  });

  final String label;
  final String suffix;
  final int initialValue;
  final ValueChanged<String> onChanged;
  final String? hint;
  final String? errorText;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(text: label, required: required),
        const SizedBox(height: 6),
        _Input(
          initialValue: initialValue,
          suffix: suffix,
          onChanged: onChanged,
          hasError: errorText != null,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText!, style: KTokens.tError),
        ] else if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint!,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: KTokens.inkSoft,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.required});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: KTokens.inkMuted,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 2),
          Text(
            '*',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: KTokens.errorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _Input extends StatefulWidget {
  const _Input({
    required this.initialValue,
    required this.suffix,
    required this.onChanged,
    required this.hasError,
  });
  final int initialValue;
  final String suffix;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.hasError ? KTokens.errorColor : KTokens.borderStrong;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(KTokens.rSm),
      borderSide: BorderSide(color: borderColor),
    );

    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: widget.onChanged,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        color: KTokens.ink,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixText: widget.suffix,
        suffixStyle: GoogleFonts.inter(
          fontSize: 12,
          color: KTokens.inkSoft,
        ),
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KTokens.rSm),
          borderSide: BorderSide(
            color: widget.hasError ? KTokens.errorColor : KTokens.accent,
            width: 1.5,
          ),
        ),
        errorBorder: border,
        focusedErrorBorder: border,
        filled: true,
        fillColor: KTokens.surface,
      ),
    );
  }
}
