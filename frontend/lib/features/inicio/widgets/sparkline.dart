import 'package:flutter/material.dart';

import '../../agenda/register/konecta_tokens.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final max = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _Bar(
                value: values[i],
                max: max,
                isLast: i == values.length - 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.max,
    required this.isLast,
  });

  final int value;
  final int max;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? value / max : 0.0;
    final height = (ratio * 56).clamp(4.0, 56.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isLast
              ? KTokens.accent
              : const Color(0x263B2F63),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
