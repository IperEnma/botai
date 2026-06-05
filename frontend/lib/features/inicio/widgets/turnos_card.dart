import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../controllers/inicio_controller.dart';
import '../models/kpi_models.dart';
import 'now_divider.dart';
import 'turno_row.dart';

class TurnosCard extends ConsumerStatefulWidget {
  const TurnosCard({super.key, required this.tenantId});

  final String tenantId;

  @override
  ConsumerState<TurnosCard> createState() => _TurnosCardState();
}

class _TurnosCardState extends ConsumerState<TurnosCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inicioControllerProvider(widget.tenantId));
    final snapshot = state.filteredSnapshot;

    return Container(
      decoration: BoxDecoration(
        color: KTokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KTokens.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(snapshot: snapshot),
          const SizedBox(height: 12),
          if (snapshot == null || snapshot.upcomingToday.isEmpty)
            _EmptyState()
          else
            _TurnosList(
              turnos: snapshot.upcomingToday,
              now: _now,
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.snapshot});

  final dynamic snapshot;

  @override
  Widget build(BuildContext context) {
    final total = snapshot?.turnos.total as int? ?? 0;
    final capacity = snapshot?.turnos.capacity as int? ?? 0;
    final libres = capacity - total;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROXIMOS TURNOS',
              style: KTokens.tEyebrow,
            ),
            const SizedBox(height: 4),
            Text(
              'HOY · $total TOTAL · $libres LIBRES',
              style: KTokens.tMonoHint,
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => context.go('/agenda/panel?section=agenda'),
          child: Text(
            'Ver agenda completa →',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: KTokens.inkSoft,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _TurnosList extends StatelessWidget {
  const _TurnosList({
    required this.turnos,
    required this.now,
  });

  final List<TurnoSummary> turnos;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final sorted = [...turnos]..sort((a, b) => a.time.compareTo(b.time));

    final past =
        sorted.where((t) => t.time.isBefore(now)).toList().reversed.take(3).toList().reversed.toList();
    final future = sorted.where((t) => !t.time.isBefore(now)).take(6).toList();

    final items = <Widget>[];

    for (final t in past) {
      items.add(TurnoRow(turno: t, isPast: true));
    }

    items.add(NowDivider(nextCount: future.length));

    for (final t in future) {
      items.add(TurnoRow(turno: t, isPast: false));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            'Sin turnos para hoy',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: KTokens.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Buena oportunidad para descansar',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: KTokens.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: KTokens.accent,
              side: const BorderSide(color: KTokens.accent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'Agendar uno',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
