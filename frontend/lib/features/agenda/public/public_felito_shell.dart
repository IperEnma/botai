import 'package:flutter/material.dart';

import 'public_reservar_layout.dart';

/// Padding horizontal compartido del shell de reserva.
const _kShellPad = 16.0;

/// Shell del wizard de reserva — mismo lenguaje visual que [PublicBusinessProfileScreen].
class PublicFelitoBookingShell extends StatelessWidget {
  const PublicFelitoBookingShell({
    super.key,
    required this.businessName,
    required this.theme,
    required this.child,
    this.onBack,
    this.progressCurrent,
    this.progressTotal,
    this.progressStepLabel,
    this.footer,
  });

  final String businessName;
  final PublicReservarTheme theme;
  final Widget child;
  final VoidCallback? onBack;
  final int? progressCurrent;
  final int? progressTotal;
  final String? progressStepLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final hasProgress =
        progressCurrent != null && progressTotal != null && progressTotal! > 0;
    final stepLabel = progressStepLabel?.trim();

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, _kShellPad, 0),
              child: Row(
                children: [
                  if (onBack != null)
                    _BackBtn(onTap: onBack!, theme: theme)
                  else
                    const SizedBox(width: 38),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textStyle(size: 16, weight: FontWeight.w700),
                        ),
                        if (hasProgress && stepLabel != null && stepLabel.isNotEmpty)
                          Text(
                            'Paso $progressCurrent de $progressTotal · $stepLabel',
                            style: theme.textStyle(size: 12, color: theme.textSub),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),
            if (hasProgress) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _kShellPad),
                child: _StepBar(
                  current: progressCurrent!,
                  total: progressTotal!,
                  theme: theme,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(child: child),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(_kShellPad, 4, _kShellPad, 8),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.onTap, required this.theme});

  final VoidCallback onTap;
  final PublicReservarTheme theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.arrow_back_ios_new, size: 16, color: theme.text),
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({
    required this.current,
    required this.total,
    required this.theme,
  });

  final int current;
  final int total;
  final PublicReservarTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final step = i + 1;
        final done = step < current;
        final active = step == current;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: active || done
                  ? theme.primary
                  : theme.primary.withValues(alpha: 0.18),
            ),
          ),
        );
      }),
    );
  }
}

Widget felitoFooterLink({
  required PublicReservarTheme theme,
  required VoidCallback onTap,
  required String label,
}) {
  return Center(
    child: TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: theme.textStyle(
          size: 14,
          weight: FontWeight.w600,
          color: theme.primary,
        ),
      ),
    ),
  );
}
