import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../konecta_tokens.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.step,
    required this.total,
    required this.onBack,
    this.showBrand = false,
  });

  final int          step;
  final int          total;
  final VoidCallback onBack;
  /// Desktop mode: show wordmark + single-row layout with fixed-width progress.
  final bool         showBrand;

  @override
  Widget build(BuildContext context) {
    final progress    = (step + 1) / total;
    final backButton  = _BackButton(onBack: onBack);
    final counterText = Text('${step + 1} / $total', style: KTokens.tMonoHint);
    final progressBar = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context2, v, child2) => LinearProgressIndicator(
        value:           v,
        minHeight:       3,
        backgroundColor: KTokens.border,
        color:           KTokens.accent,
        borderRadius:    BorderRadius.circular(KTokens.rPill),
      ),
    );

    if (showBrand) {
      // Desktop: back · konecta · spacer · [progress 140px] · N/5
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 40, 0),
        child: Row(
          children: [
            backButton,
            const SizedBox(width: 16),
            Text(
              'konecta',
              style: GoogleFonts.instrumentSerif(
                fontSize:  18,
                fontStyle: FontStyle.italic,
                color:     KTokens.ink,
              ),
            ),
            const Spacer(),
            SizedBox(width: 140, child: progressBar),
            const SizedBox(width: 12),
            counterText,
          ],
        ),
      );
    }

    // Mobile: single-row layout [← | progress | N/5]
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          backButton,
          const SizedBox(width: 12),
          Expanded(child: progressBar),
          const SizedBox(width: 12),
          counterText,
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // 44×44 touch target, 36×36 visual
    return SizedBox(
      width:  44,
      height: 44,
      child: GestureDetector(
        onTap: onBack,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:        KTokens.surface,
              borderRadius: BorderRadius.circular(KTokens.rPill),
              border:       Border.all(color: KTokens.border),
            ),
            child: const Icon(Icons.arrow_back, size: 18, color: KTokens.ink),
          ),
        ),
      ),
    );
  }
}
