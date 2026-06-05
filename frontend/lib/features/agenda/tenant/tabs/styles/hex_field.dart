import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../register/konecta_tokens.dart';
import 'brand_style.dart';

/// Pill con muestra de color + texto HEX editable. Auto-prepend `#`.
class HexField extends StatefulWidget {
  const HexField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<HexField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.replaceAll('#', ''));
    _focus = FocusNode();
    _focus.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(HexField old) {
    super.didUpdateWidget(old);
    final current = widget.value.replaceAll('#', '');
    if (!_focus.hasFocus && _ctrl.text.toUpperCase() != current.toUpperCase()) {
      _ctrl.text = current;
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  void _handleFocusChange() {
    if (!_focus.hasFocus) {
      // On blur, commit only if valid
      final normalized = normalizeHex(_ctrl.text);
      if (normalized == null) {
        _ctrl.text = widget.value.replaceAll('#', '');
      } else {
        widget.onChanged(normalized);
      }
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_handleFocusChange);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = parseHex(widget.value, fallback: KTokens.accent);
    final isLight = !isDark(widget.value);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.borderStrong),
        borderRadius: BorderRadius.circular(KTokens.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isLight
                  ? Border.all(color: KTokens.borderStrong)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
              ],
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: KTokens.ink,
                letterSpacing: 0.4,
              ),
              decoration: InputDecoration(
                prefixText: '#',
                prefixStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: KTokens.inkSoft,
                ),
                hintText: 'RRGGBB',
                hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: KTokens.inkPlaceholder,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _focus.unfocus(),
              onChanged: (v) {
                if (v.length == 6) {
                  final normalized = normalizeHex(v);
                  if (normalized != null) widget.onChanged(normalized);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
