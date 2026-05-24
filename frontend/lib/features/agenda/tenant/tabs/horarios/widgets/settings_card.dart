import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../../../../providers/agenda/tenant/horarios_controller_provider.dart';

class SettingsCard extends ConsumerWidget {
  const SettingsCard({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  ({String tenantId, String businessId}) get _key =>
      (tenantId: tenantId, businessId: businessId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(
      horariosControllerProvider(_key).select((s) => s.rules),
    );
    final notifier = ref.read(horariosControllerProvider(_key).notifier);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reglas de los turnos',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: KTokens.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cómo se generan los slots que ofrecés a los clientes.',
            style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkMuted),
          ),
          const SizedBox(height: 16),
          // 2x2 grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              if (isNarrow) {
                return Column(
                  children: [
                    _SlotDurationBox(rules: rules, onChanged: (r) => notifier.updateRules(r)),
                    const SizedBox(height: 12),
                    _BufferBox(rules: rules, onChanged: (r) => notifier.updateRules(r)),
                    const SizedBox(height: 12),
                    _MinLeadBox(rules: rules, onChanged: (r) => notifier.updateRules(r)),
                    const SizedBox(height: 12),
                    _MaxLeadBox(rules: rules, onChanged: (r) => notifier.updateRules(r)),
                  ],
                );
              }
              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _SlotDurationBox(
                            rules: rules,
                            onChanged: (r) => notifier.updateRules(r),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BufferBox(
                            rules: rules,
                            onChanged: (r) => notifier.updateRules(r),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _MinLeadBox(
                            rules: rules,
                            onChanged: (r) => notifier.updateRules(r),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MaxLeadBox(
                            rules: rules,
                            onChanged: (r) => notifier.updateRules(r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RuleBox extends StatelessWidget {
  const _RuleBox({
    required this.eyebrow,
    required this.child,
  });

  final String eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KTokens.bg,
        borderRadius: BorderRadius.circular(KTokens.rSm),
        border: Border.all(color: KTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              letterSpacing: 1.2,
              color: KTokens.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SlotDurationBox extends StatelessWidget {
  const _SlotDurationBox({required this.rules, required this.onChanged});
  final BookingRulesDraft rules;
  final void Function(BookingRulesDraft) onChanged;

  @override
  Widget build(BuildContext context) {
    return _RuleBox(
      eyebrow: 'DURACIÓN DE LOS SLOTS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented buttons
          Row(
            children: [
              _SegBtn(
                label: 'Por servicio',
                selected: rules.byService,
                onTap: () => onChanged(rules.copyWith(byService: true)),
              ),
              const SizedBox(width: 6),
              _SegBtn(
                label: 'Fija',
                selected: !rules.byService,
                onTap: () => onChanged(rules.copyWith(byService: false)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rules.byService)
            Text(
              'Los slots toman la duración del servicio elegido. Recomendado.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: KTokens.inkMuted,
                height: 1.45,
              ),
            )
          else ...[
            Text(
              'Duración fija (min)',
              style: GoogleFonts.inter(fontSize: 11, color: KTokens.inkMuted),
            ),
            const SizedBox(height: 6),
            _MinuteStepper(
              value: rules.fixedSlotMin,
              options: const [15, 30, 45, 60],
              onChanged: (v) => onChanged(rules.copyWith(fixedSlotMin: v)),
            ),
          ],
        ],
      ),
    );
  }
}

class _BufferBox extends StatelessWidget {
  const _BufferBox({required this.rules, required this.onChanged});
  final BookingRulesDraft rules;
  final void Function(BookingRulesDraft) onChanged;

  @override
  Widget build(BuildContext context) {
    return _RuleBox(
      eyebrow: 'BUFFER ENTRE TURNOS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${rules.bufferMin}',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: KTokens.ink,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'min',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: KTokens.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepperBtn(
                icon: Icons.remove,
                onTap: rules.bufferMin > 0
                    ? () => onChanged(
                          rules.copyWith(bufferMin: rules.bufferMin - 5),
                        )
                    : null,
              ),
              const SizedBox(width: 8),
              _StepperBtn(
                icon: Icons.add,
                onTap: rules.bufferMin < 60
                    ? () => onChanged(
                          rules.copyWith(bufferMin: rules.bufferMin + 5),
                        )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tiempo de limpieza o preparación entre cada cliente.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: KTokens.inkMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MinLeadBox extends StatelessWidget {
  const _MinLeadBox({required this.rules, required this.onChanged});
  final BookingRulesDraft rules;
  final void Function(BookingRulesDraft) onChanged;

  @override
  Widget build(BuildContext context) {
    return _RuleBox(
      eyebrow: 'ANTICIPACIÓN MÍNIMA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${rules.minLeadHours}',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: KTokens.ink,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'horas',
                style: GoogleFonts.inter(fontSize: 14, color: KTokens.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepperBtn(
                icon: Icons.remove,
                onTap: rules.minLeadHours > 0
                    ? () => onChanged(
                          rules.copyWith(minLeadHours: rules.minLeadHours - 1),
                        )
                    : null,
              ),
              const SizedBox(width: 8),
              _StepperBtn(
                icon: Icons.add,
                onTap: rules.minLeadHours < 72
                    ? () => onChanged(
                          rules.copyWith(minLeadHours: rules.minLeadHours + 1),
                        )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cuánto antes deben reservar los clientes.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: KTokens.inkMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaxLeadBox extends StatelessWidget {
  const _MaxLeadBox({required this.rules, required this.onChanged});
  final BookingRulesDraft rules;
  final void Function(BookingRulesDraft) onChanged;

  @override
  Widget build(BuildContext context) {
    return _RuleBox(
      eyebrow: 'ANTICIPACIÓN MÁXIMA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${rules.maxLeadDays}',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: KTokens.ink,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'días',
                style: GoogleFonts.inter(fontSize: 14, color: KTokens.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepperBtn(
                icon: Icons.remove,
                onTap: rules.maxLeadDays > 7
                    ? () => onChanged(
                          rules.copyWith(maxLeadDays: rules.maxLeadDays - 7),
                        )
                    : null,
              ),
              const SizedBox(width: 8),
              _StepperBtn(
                icon: Icons.add,
                onTap: rules.maxLeadDays < 365
                    ? () => onChanged(
                          rules.copyWith(maxLeadDays: rules.maxLeadDays + 7),
                        )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hasta cuándo en el futuro pueden agendar.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: KTokens.inkMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? KTokens.accent : Colors.white,
          borderRadius: BorderRadius.circular(KTokens.rSm),
          border: Border.all(
            color: selected ? KTokens.accent : KTokens.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : KTokens.ink,
          ),
        ),
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : KTokens.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: KTokens.border),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? KTokens.ink : KTokens.inkPlaceholder,
        ),
      ),
    );
  }
}

class _MinuteStepper extends StatelessWidget {
  const _MinuteStepper({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final int value;
  final List<int> options;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: options.map((v) {
        final selected = v == value;
        return GestureDetector(
          onTap: () => onChanged(v),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? KTokens.accent : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? KTokens.accent : KTokens.border,
              ),
            ),
            child: Text(
              '${v}m',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: selected ? Colors.white : KTokens.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KTokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}
