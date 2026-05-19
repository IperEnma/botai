import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../register/konecta_tokens.dart';
import '../../models/member.dart';
import '../../providers/equipo_provider.dart';

class DetailScheduleTab extends StatefulWidget {
  const DetailScheduleTab({
    super.key,
    required this.member,
    required this.notifier,
  });

  final Member member;
  final EquipoNotifier notifier;

  @override
  State<DetailScheduleTab> createState() => _DetailScheduleTabState();
}

class _DetailScheduleTabState extends State<DetailScheduleTab> {
  late bool _customEnabled;

  @override
  void initState() {
    super.initState();
    _customEnabled = widget.member.isCustomSchedule;
  }

  void _toggleCustom(bool value) {
    setState(() => _customEnabled = value);
    if (!value) {
      widget.notifier.updateMember(
        widget.member.copyWith(clearCustomSchedule: true),
      );
    } else {
      // Enable with a default schedule
      widget.notifier.updateMember(
        widget.member.copyWith(
          customSchedule: const WeekSchedule(
            lunes: DaySchedule(open: true, from: '09:00', to: '18:00'),
            martes: DaySchedule(open: true, from: '09:00', to: '18:00'),
            miercoles: DaySchedule(open: true, from: '09:00', to: '18:00'),
            jueves: DaySchedule(open: true, from: '09:00', to: '18:00'),
            viernes: DaySchedule(open: true, from: '09:00', to: '18:00'),
            sabado: DaySchedule(open: false),
            domingo: DaySchedule(open: false),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final sched = member.customSchedule;
    final memberName = member.name.split(' ').first.toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: KTokens.border),
              borderRadius: BorderRadius.circular(KTokens.rSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Horario personalizado',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: KTokens.ink,
                        ),
                      ),
                    ),
                    Switch(
                      value: _customEnabled,
                      onChanged: _toggleCustom,
                      activeThumbColor: KTokens.accent,
                      activeTrackColor: KTokens.accentSoft,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'CUANDO ESTÁ OFF, $memberName HEREDA EL HORARIO DEL NEGOCIO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: KTokens.inkSoft,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Schedule grid
          if (_customEnabled && sched != null) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: KTokens.border),
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              child: Column(
                children: _buildDayRows(sched),
              ),
            ),

            // Warning if domingo is open
            if (sched.domingo.open) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: KTokens.excModifiedBg,
                  border: Border.all(color: KTokens.memberPausedBg),
                  borderRadius: BorderRadius.circular(KTokens.rSm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: KTokens.excModified),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El domingo está marcado como abierto, pero el negocio no atiende ese día.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: KTokens.excModified,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDayRows(WeekSchedule sched) {
    final days = [
      ('Lunes', 'LUN', sched.lunes),
      ('Martes', 'MAR', sched.martes),
      ('Miércoles', 'MIÉ', sched.miercoles),
      ('Jueves', 'JUE', sched.jueves),
      ('Viernes', 'VIE', sched.viernes),
      ('Sábado', 'SÁB', sched.sabado),
      ('Domingo', 'DOM', sched.domingo),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < days.length; i++) {
      final (name, abbrev, day) = days[i];
      rows.add(_DayRow(name: name, abbrev: abbrev, day: day));
      if (i < days.length - 1) {
        rows.add(const Divider(height: 1, color: KTokens.border));
      }
    }
    return rows;
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.name,
    required this.abbrev,
    required this.day,
  });

  final String name;
  final String abbrev;
  final DaySchedule day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Dot indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: day.open ? KTokens.accent : KTokens.border,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Day name + abbrev
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: day.open ? KTokens.ink : KTokens.inkMuted,
                  ),
                ),
                Text(
                  abbrev,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: KTokens.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Time or Libre
          Text(
            day.open
                ? '${day.from ?? ''} – ${day.to ?? ''}'
                : 'Libre',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: day.open ? KTokens.ink : KTokens.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
