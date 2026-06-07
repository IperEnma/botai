import 'package:flutter/material.dart';

import '../../../features/agenda/register/konecta_tokens.dart';

class KToggle extends StatelessWidget {
  const KToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  static const _trackW = 44.0;
  static const _trackH = 26.0;
  static const _knobD  = 20.0;
  static const _pad    = (_trackH - _knobD) / 2;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: _trackW,
          height: _trackH,
          child: _TrackAnimated(value: value),
        ),
      ),
    );
  }
}

class _TrackAnimated extends StatelessWidget {
  const _TrackAnimated({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value ? 1.0 : 0.0, end: value ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 150),
      builder: (context, t, child) {
        final trackColor = Color.lerp(
          const Color(0x29000000),
          KTokens.accent,
          t,
        )!;
        final left = KToggle._pad + t * (KToggle._trackW - KToggle._knobD - KToggle._pad * 2);
        return Container(
          width: KToggle._trackW,
          height: KToggle._trackH,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(KToggle._trackH / 2),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                left: left,
                top: KToggle._pad,
                child: Container(
                  width: KToggle._knobD,
                  height: KToggle._knobD,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
