import 'package:flutter/material.dart';

import '../konecta_tokens.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.onNext,
    required this.canContinue,
    required this.isLast,
    this.onSkip,
    this.maxWidth,
  });

  final VoidCallback? onSkip;
  final VoidCallback onNext;
  final bool canContinue;
  final bool isLast;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: KTokens.bg,
        border: Border(top: BorderSide(color: KTokens.border, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: maxWidth ?? double.infinity),
              child: Row(
                children: [
                  if (onSkip != null) ...[
                    OutlinedButton(
                      onPressed: onSkip,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: KTokens.borderStrong),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(KTokens.rMd),
                        ),
                        foregroundColor: KTokens.inkMuted,
                      ),
                      child: Text('Saltar',
                          style:
                              KTokens.tCta.copyWith(color: KTokens.inkMuted)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Opacity(
                      opacity: canContinue ? 1.0 : 0.4,
                      child: ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KTokens.ink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(KTokens.rMd),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isLast ? 'Registrar →' : 'Continuar →',
                          style: KTokens.tCta.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
