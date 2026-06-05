import 'package:flutter/material.dart';

import '../../../register/konecta_tokens.dart';
import 'brand_style.dart';
import 'hex_field.dart';

/// Bloque de swatches + HEX editable. Sirve para "Color principal" y "Color de fondo".
class ColorBlock extends StatelessWidget {
  const ColorBlock({
    super.key,
    required this.swatches,
    required this.value,
    required this.onChanged,
    this.bordered = false,
  });

  final List<String> swatches;
  final String value;
  final ValueChanged<String> onChanged;

  /// Si true, los swatches llevan un borde sutil (recomendado para fondos claros).
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final hex in swatches)
          _Swatch(
            hex: hex,
            selected: hex.toUpperCase() == value.toUpperCase(),
            bordered: bordered,
            onTap: () => onChanged(hex.toUpperCase()),
          ),
        HexField(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.hex,
    required this.selected,
    required this.bordered,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final bool bordered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = parseHex(hex);
    return Semantics(
      label: 'Color $hex',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: bordered
                    ? Border.all(color: KTokens.borderStrong, width: 1)
                    : null,
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 0,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: KTokens.accent,
                          blurRadius: 0,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
