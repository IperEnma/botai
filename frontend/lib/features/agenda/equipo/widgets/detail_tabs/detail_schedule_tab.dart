import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../models/agenda/business_hours.dart';
import '../../../../../providers/agenda/tenant/business_hours_provider.dart';
import '../../../register/konecta_tokens.dart';
import '../../models/member.dart';
import '../../providers/equipo_provider.dart';

class DetailScheduleTab extends ConsumerStatefulWidget {
  const DetailScheduleTab({
    super.key,
    required this.member,
    required this.notifier,
    required this.tenantId,
    required this.businessId,
  });

  final Member member;
  final EquipoNotifier notifier;
  final String tenantId;
  final String businessId;

  @override
  ConsumerState<DetailScheduleTab> createState() => _DetailScheduleTabState();
}

class _DetailScheduleTabState extends ConsumerState<DetailScheduleTab> {
  late bool _customEnabled;

  @override
  void initState() {
    super.initState();
    _customEnabled = widget.member.isCustomSchedule;
  }

  @override
  void didUpdateWidget(covariant DetailScheduleTab old) {
    super.didUpdateWidget(old);
    if (old.member.id != widget.member.id) {
      _customEnabled = widget.member.isCustomSchedule;
    }
  }

  void _toggleCustom(bool value, List<BusinessHours> bizHours) {
    setState(() => _customEnabled = value);
    if (!value) {
      widget.notifier.updateMember(
        widget.member.copyWith(clearCustomSchedule: true),
      );
      return;
    }

    // Build initial schedule respecting business hours
    DaySchedule fromBiz(int diaSemana) {
      final h = bizHours.where((e) => e.diaSemana == diaSemana).firstOrNull;
      if (h == null || h.cerrado) return const DaySchedule(open: false);
      return DaySchedule(
        open: true,
        from: h.apertura ?? '09:00',
        to: h.cierre ?? '18:00',
      );
    }

    widget.notifier.updateMember(
      widget.member.copyWith(
        customSchedule: WeekSchedule(
          lunes:     fromBiz(0),
          martes:    fromBiz(1),
          miercoles: fromBiz(2),
          jueves:    fromBiz(3),
          viernes:   fromBiz(4),
          sabado:    fromBiz(5),
          domingo:   fromBiz(6),
        ),
      ),
    );
  }

  WeekSchedule _updateDay(WeekSchedule sched, int index, DaySchedule day) {
    return WeekSchedule(
      lunes:     index == 0 ? day : sched.lunes,
      martes:    index == 1 ? day : sched.martes,
      miercoles: index == 2 ? day : sched.miercoles,
      jueves:    index == 3 ? day : sched.jueves,
      viernes:   index == 4 ? day : sched.viernes,
      sabado:    index == 5 ? day : sched.sabado,
      domingo:   index == 6 ? day : sched.domingo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoursState = ref.watch(
      businessHoursProvider((tenantId: widget.tenantId, businessId: widget.businessId)),
    );

    if (hoursState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No se pudo cargar el horario del negocio',
              style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(
                businessHoursProvider((tenantId: widget.tenantId, businessId: widget.businessId)),
              ),
              child: Text(
                'Reintentar',
                style: GoogleFonts.inter(fontSize: 13, color: KTokens.accent),
              ),
            ),
          ],
        ),
      );
    }

    // While loading OR when no hours have been saved yet, treat every day as
    // closed. This matches what the hours tab displays (all-CERRADO default)
    // and prevents editing member schedules without a business-hours reference.
    final bizHours = (hoursState.isLoading || hoursState.hours.isEmpty)
        ? List.generate(
            7,
            (i) => BusinessHours(
              id: '',
              businessId: widget.businessId,
              diaSemana: i,
              cerrado: true,
            ),
          )
        : hoursState.hours;

    final member = widget.member;
    final sched = member.customSchedule;
    final memberName = member.name.split(' ').first.toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      onChanged: (v) => _toggleCustom(v, bizHours),
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

          if (_customEnabled && sched != null) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: KTokens.border),
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              child: Column(
                children: _buildDayRows(sched, bizHours),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDayRows(WeekSchedule sched, List<BusinessHours> bizHours) {
    final days = [
      ('Lunes',      'LUN', sched.lunes,     0),
      ('Martes',     'MAR', sched.martes,    1),
      ('Miércoles',  'MIÉ', sched.miercoles, 2),
      ('Jueves',     'JUE', sched.jueves,    3),
      ('Viernes',    'VIE', sched.viernes,   4),
      ('Sábado',     'SÁB', sched.sabado,    5),
      ('Domingo',    'DOM', sched.domingo,   6),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < days.length; i++) {
      final (name, abbrev, day, diaSemana) = days[i];
      final bh = bizHours.where((e) => e.diaSemana == diaSemana).firstOrNull;
      final bizClosed = bh != null && bh.cerrado;

      rows.add(_DayRow(
        name: name,
        abbrev: abbrev,
        day: bizClosed ? const DaySchedule(open: false) : day,
        businessHours: bh,
        bizClosed: bizClosed,
        onChanged: bizClosed
            ? null
            : (updated) {
                final newSched = _updateDay(sched, i, updated);
                widget.notifier.updateMember(
                  widget.member.copyWith(customSchedule: newSched),
                );
              },
      ));
      if (i < days.length - 1) {
        rows.add(const Divider(height: 1, color: KTokens.border));
      }
    }
    return rows;
  }
}

// ─── Day row ──────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.name,
    required this.abbrev,
    required this.day,
    required this.onChanged,
    this.businessHours,
    this.bizClosed = false,
  });

  final String name;
  final String abbrev;
  final DaySchedule day;
  final ValueChanged<DaySchedule>? onChanged;
  final BusinessHours? businessHours;
  final bool bizClosed;

  TimeOfDay _parseTime(String? t, {int defaultHour = 9}) {
    if (t == null || t.isEmpty) return TimeOfDay(hour: defaultHour, minute: 0);
    final parts = t.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? defaultHour,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _clampToBizHours(TimeOfDay t) {
    if (businessHours == null) return t;
    final minT = _parseTime(businessHours!.apertura, defaultHour: 0);
    final maxT = _parseTime(businessHours!.cierre, defaultHour: 23);
    final mins = (t.hour * 60 + t.minute)
        .clamp(minT.hour * 60 + minT.minute, maxT.hour * 60 + maxT.minute);
    return TimeOfDay(hour: mins ~/ 60, minute: mins % 60);
  }

  Future<void> _pickTime(BuildContext context, bool isFrom) async {
    final initial = _parseTime(isFrom ? day.from : day.to, defaultHour: isFrom ? 9 : 18);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;
    final clamped = _clampToBizHours(picked);

    if (clamped != picked && businessHours != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El horario del negocio es de ${businessHours!.apertura} a ${businessHours!.cierre}. '
            'Se ajustó tu selección automáticamente.',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    onChanged!(DaySchedule(
      open: day.open,
      from: isFrom ? _formatTime(clamped) : day.from,
      to: isFrom ? day.to : _formatTime(clamped),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = bizClosed ? KTokens.border : (day.open ? KTokens.accent : KTokens.border);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: effectiveColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          SizedBox(
            width: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: bizClosed || !day.open ? KTokens.inkMuted : KTokens.ink,
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

          if (bizClosed)
            Text(
              'Negocio cerrado',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: KTokens.inkPlaceholder,
              ),
            )
          else if (day.open) ...[
            _TimeChip(
              time: day.from ?? '09:00',
              onTap: () => _pickTime(context, true),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '–',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: KTokens.inkSoft,
                ),
              ),
            ),
            _TimeChip(
              time: day.to ?? '18:00',
              onTap: () => _pickTime(context, false),
            ),
          ] else
            Text(
              'Libre',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: KTokens.inkSoft,
              ),
            ),

          const SizedBox(width: 12),

          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: day.open,
              onChanged: bizClosed
                  ? null
                  : (v) => onChanged!(DaySchedule(
                        open: v,
                        from: v ? (day.from ?? businessHours?.apertura ?? '09:00') : null,
                        to:   v ? (day.to   ?? businessHours?.cierre   ?? '18:00') : null,
                      )),
              activeThumbColor: KTokens.accent,
              activeTrackColor: KTokens.accentSoft,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Time chip ────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time, required this.onTap});
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: KTokens.surface,
          border: Border.all(color: KTokens.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          time,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: KTokens.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
