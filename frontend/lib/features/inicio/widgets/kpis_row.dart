import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../controllers/inicio_controller.dart';
import 'kpi_card.dart';

const _kBreakpointMobile = 768.0;

class KpisRow extends ConsumerWidget {
  const KpisRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inicioControllerProvider);
    final snapshot = state.filteredSnapshot;
    if (snapshot == null) return const SizedBox.shrink();

    final isMobile =
        MediaQuery.sizeOf(context).width < _kBreakpointMobile;

    final cards = [
      KpiCard(
        label: 'Turnos hoy',
        value: '${snapshot.turnos.total}',
        unit: 'DE ${snapshot.turnos.capacity} POSIBLES',
        trendPct: snapshot.turnos.trendPct,
        breakdown: _TurnosByBranchBreakdown(
          byBranch: snapshot.turnos.byBranch,
          branches: snapshot.branches,
        ),
      ),
      KpiCard(
        label: 'Ingreso esperado',
        value: 'UY\$ ${_fmtMoney(snapshot.revenue.expectedUyu)}',
        unit: '',
        trendPct: snapshot.revenue.trendPct,
        breakdown: _RevenueBreakdown(
          collected: snapshot.revenue.collectedUyu,
          pending: snapshot.revenue.pendingUyu,
        ),
      ),
      KpiCard(
        label: 'Ocupación promedio',
        value: snapshot.occupancy.averagePct.toStringAsFixed(0),
        unit: '%',
        trendPct: snapshot.occupancy.trendPct,
        breakdown: _OccupancyBreakdown(
          byBranch: snapshot.occupancy.byBranch,
          branches: snapshot.branches,
        ),
      ),
      KpiCard(
        label: 'Turnos del bot',
        value: '${snapshot.bot.turnosFromBot}',
        unit:
            'DE ${snapshot.bot.turnosTotal} · ${snapshot.bot.botPct.toStringAsFixed(0)}%',
        trendPct: snapshot.bot.trendPct,
        breakdown: _BotBreakdown(
          fromBot: snapshot.bot.turnosFromBot,
          manual: snapshot.bot.turnosManual,
        ),
      ),
    ];

    if (isMobile) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final card in cards)
            SizedBox(
              width: (MediaQuery.sizeOf(context).width - 76) / 2,
              child: card,
            ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }

  static String _fmtMoney(int amount) {
    if (amount >= 1000) {
      final str = amount.toString();
      final rem = str.length % 3;
      final parts = <String>[];
      for (int i = rem == 0 ? 3 : rem; i <= str.length; i += 3) {
        if (i - 3 < 0) {
          parts.add(str.substring(0, rem));
        } else {
          parts.add(str.substring(i - 3, i));
        }
      }
      if (rem != 0) {
        return '${str.substring(0, rem)}.${str.substring(rem)}';
      }
      return amount.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    return amount.toString();
  }
}

class _TurnosByBranchBreakdown extends StatelessWidget {
  const _TurnosByBranchBreakdown({
    required this.byBranch,
    required this.branches,
  });

  final Map<String, int> byBranch;
  final List<dynamic> branches;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final entry in byBranch.entries)
          _DotLabel(
            color: _colorForBranch(entry.key),
            label: '${entry.value}',
          ),
      ],
    );
  }

  Color _colorForBranch(String id) {
    for (final b in branches) {
      if ((b as dynamic).id == id) return b.color as Color;
    }
    return KTokens.inkPlaceholder;
  }
}

class _RevenueBreakdown extends StatelessWidget {
  const _RevenueBreakdown({
    required this.collected,
    required this.pending,
  });

  final int collected;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        Text(
          'UY\$ $collected COBRADO',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: KTokens.trendUp,
          ),
        ),
        Text(
          '· UY\$ $pending PENDIENTE',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: KTokens.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _OccupancyBreakdown extends StatelessWidget {
  const _OccupancyBreakdown({
    required this.byBranch,
    required this.branches,
  });

  final Map<String, double> byBranch;
  final List<dynamic> branches;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final entry in byBranch.entries)
          _DotLabel(
            color: _colorForBranch(entry.key),
            label: '${entry.value.toStringAsFixed(0)}%',
          ),
      ],
    );
  }

  Color _colorForBranch(String id) {
    for (final b in branches) {
      if ((b as dynamic).id == id) return b.color as Color;
    }
    return KTokens.inkPlaceholder;
  }
}

class _BotBreakdown extends StatelessWidget {
  const _BotBreakdown({
    required this.fromBot,
    required this.manual,
  });

  final int fromBot;
  final int manual;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        _DotLabel(
          color: KTokens.accent,
          label: 'BOT $fromBot',
        ),
        _DotLabel(
          color: KTokens.inkSoft,
          label: 'MANUAL $manual',
        ),
      ],
    );
  }
}

class _DotLabel extends StatelessWidget {
  const _DotLabel({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: KTokens.inkSoft,
          ),
        ),
      ],
    );
  }
}
