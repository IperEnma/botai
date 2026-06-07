import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/register/konecta_tokens.dart';

class ConfigDataRow extends StatelessWidget {
  const ConfigDataRow({
    super.key,
    required this.label,
    required this.child,
    this.isFirst = false,
  });

  final String label;
  final Widget child;
  final bool isFirst;

  static const _labelW = 160.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst)
          const Divider(height: 1, thickness: 1, color: KTokens.border),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _labelW,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: KTokens.inkMuted,
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

class ConfigDataText extends StatelessWidget {
  const ConfigDataText(this.text, {super.key, this.italic = false});
  final String text;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: italic ? KTokens.inkPlaceholder : KTokens.ink,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }
}
