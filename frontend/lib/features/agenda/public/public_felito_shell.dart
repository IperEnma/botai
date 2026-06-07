import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens visuales del flujo público (perfil + reserva) — mockup Felito Barber.
abstract final class FelitoPublicD {
  static const purple = Color(0xFF7C5CFF);
  static const bg = Color(0xFFF3F4F6);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const white = Colors.white;
  static const pad = 16.0;

  static TextStyle t(
    double s, {
    FontWeight w = FontWeight.w400,
    Color c = ink,
    double? h,
  }) =>
      GoogleFonts.inter(fontSize: s, fontWeight: w, color: c, height: h);
}

/// Shell del wizard de reserva — mismo lenguaje visual que [PublicBusinessProfileScreen].
class PublicFelitoBookingShell extends StatelessWidget {
  const PublicFelitoBookingShell({
    super.key,
    required this.businessName,
    required this.child,
    this.onBack,
    this.progressCurrent,
    this.progressTotal,
    this.progressStepLabel,
    this.footer,
  });

  final String businessName;
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
      backgroundColor: FelitoPublicD.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, FelitoPublicD.pad, 0),
              child: Row(
                children: [
                  if (onBack != null)
                    _BackBtn(onTap: onBack!)
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
                          style: FelitoPublicD.t(16, w: FontWeight.w700),
                        ),
                        if (hasProgress && stepLabel != null && stepLabel.isNotEmpty)
                          Text(
                            'Paso $progressCurrent de $progressTotal · $stepLabel',
                            style: FelitoPublicD.t(12, c: FelitoPublicD.muted),
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
                padding: const EdgeInsets.symmetric(horizontal: FelitoPublicD.pad),
                child: _StepBar(
                  current: progressCurrent!,
                  total: progressTotal!,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(child: child),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(FelitoPublicD.pad, 4, FelitoPublicD.pad, 8),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FelitoPublicD.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.arrow_back_ios_new, size: 16, color: FelitoPublicD.ink),
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.current, required this.total});

  final int current;
  final int total;

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
                  ? FelitoPublicD.purple
                  : FelitoPublicD.purple.withValues(alpha: 0.18),
            ),
          ),
        );
      }),
    );
  }
}

Widget felitoFooterLink({
  required VoidCallback onTap,
  required String label,
}) {
  return Center(
    child: TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: FelitoPublicD.t(14, w: FontWeight.w600, c: FelitoPublicD.purple),
      ),
    ),
  );
}
