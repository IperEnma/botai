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
    final usagePct = plan.usagePct;
    final usageColor = usagePct >= 1.0
        ? KTokens.excClosed
        : usagePct >= 0.8
            ? KTokens.warn
            : KTokens.inkSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'TU PLAN ACTUAL',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: KTokens.inkSoft,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 14),
          // Plan pill
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
            decoration: BoxDecoration(
              color: KTokens.accentSoft,
              borderRadius: BorderRadius.circular(KTokens.rPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: KTokens.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  plan.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: KTokens.accent,
                  ),
                ),
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
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: KTokens.inkMuted,
                ),
                children: [
                  TextSpan(text: '${_capaDescription(plan.capa)} '),
                  TextSpan(
                    text:
                        '${plan.usedMsgsThisMonth} / ${_fmtQuota(plan.monthlyMsgQuota)} mensajes este mes.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: usageColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
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
                const Icon(Icons.arrow_forward,
                    size: 14, color: KTokens.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtQuota(int n) {
    if (n >= 1000) return '${n ~/ 1000}.000';
    return n.toString();
  }
}
