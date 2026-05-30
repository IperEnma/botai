import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../controllers/inicio_controller.dart';
import 'sparkline.dart';

class ActivityCard extends ConsumerWidget {
  const ActivityCard({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inicioControllerProvider(tenantId));
    final snapshot = state.snapshot;
    if (snapshot == null) return const SizedBox.shrink();

    final activity = snapshot.activity;
    final quotaLeft =
        (100 - activity.quotaUsedPct).clamp(0.0, 100.0).toStringAsFixed(0);

    return Container(
      decoration: BoxDecoration(
        color: KTokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KTokens.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'ACTIVIDAD DEL BOT',
            style: KTokens.tEyebrow,
          ),
          const SizedBox(height: 4),
          Text(
            'ULTIMOS 7 DIAS · PROFESIONAL · CAPA 2',
            style: KTokens.tMonoHint,
          ),
          const SizedBox(height: 16),

          // Sparkline
          Sparkline(values: activity.last7Days),
          const SizedBox(height: 6),

          // Day labels
          Row(
            children: [
              for (final label in ['L', 'M', 'M', 'J', 'V', 'S', 'HOY']) ...[
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: KTokens.inkSoft,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Stats list
          _StatRow(
            label: 'Mensajes este mes',
            value: '${activity.msgsThisMonth} / ${activity.msgsQuota}',
          ),
          _StatRow(
            label: 'Conversaciones',
            value: '${activity.conversations}',
          ),
          _StatRow(
            label: 'Turnos generados',
            value: '${activity.turnosGenerated}',
          ),
          _StatRow(
            label: 'Tasa de resolución',
            value: '${activity.resolutionRate.toStringAsFixed(0)}%',
            isLast: true,
          ),
          const SizedBox(height: 16),

          // Callout
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: KTokens.accentSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: KTokens.accent.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              '● $quotaLeft% DE LA CUOTA MENSUAL DISPONIBLE · MEJORA EL PLAN PARA AMPLIAR',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: KTokens.accent,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: KTokens.border, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: KTokens.inkMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}
