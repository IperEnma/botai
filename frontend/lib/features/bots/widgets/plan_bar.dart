import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/agenda/register/konecta_tokens.dart';
import '../controllers/bots_controller.dart';
import '../models/bot.dart';

class PlanBar extends ConsumerWidget {
  const PlanBar({super.key});

  String _capaShortLabel(BotCapa capa) => switch (capa) {
        BotCapa.capa1 => 'CAPA 1 · FAQ',
        BotCapa.capa2 => 'CAPA 2 · IA HÍBRIDA',
        BotCapa.capa3 => 'CAPA 3 · CRM',
      };

  String _capaDescription(BotCapa capa) => switch (capa) {
        BotCapa.capa1 => 'Tus bots pueden usar FAQ y menús interactivos.',
        BotCapa.capa2 => 'Tus bots pueden usar FAQ + IA con tu documentación.',
        BotCapa.capa3 => 'Tus bots pueden usar IA + acciones automáticas.',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(businessPlanProvider);

    final decoration = BoxDecoration(
      color: KTokens.surface,
      border: Border.all(color: KTokens.border),
      borderRadius: BorderRadius.circular(12),
    );

    final upgradeLink = GestureDetector(
      onTap: () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mejorar plan',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: KTokens.accent,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward, size: 14, color: KTokens.accent),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        // Pill — compact on mobile (no capa label), full on desktop
        final pill = Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
          decoration: BoxDecoration(
            color: KTokens.accentSoft,
            borderRadius: BorderRadius.circular(KTokens.rPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: KTokens.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                plan.displayName,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: KTokens.accent,
                ),
              ),
              if (!isNarrow) ...[
                const SizedBox(width: 8),
                Text(
                  _capaShortLabel(plan.capa),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: KTokens.accent.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        );

        final label = Text(
          'TU PLAN ACTUAL',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: KTokens.inkSoft,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w500,
          ),
        );

        final description = Text(
          _capaDescription(plan.capa),
          style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkMuted),
        );

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: decoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    label,
                    const SizedBox(width: 10),
                    pill,
                  ],
                ),
                const SizedBox(height: 8),
                description,
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: decoration,
          child: Row(
            children: [
              label,
              const SizedBox(width: 10),
              pill,
              const SizedBox(width: 14),
              Expanded(child: description),
              const SizedBox(width: 14),
              upgradeLink,
            ],
          ),
        );
      },
    );
  }
}
