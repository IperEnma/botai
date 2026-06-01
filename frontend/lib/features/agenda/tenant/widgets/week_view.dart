import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/booking.dart';
import '../../../../models/agenda/business_hours.dart';
import '../../../../models/agenda/staff_member.dart';
import '../../../../providers/agenda/tenant/agenda_week_provider.dart';
import '../../../../providers/agenda/tenant/business_hours_provider.dart';
import '../../../../providers/agenda/tenant/business_staff_provider.dart';
import '../../register/konecta_tokens.dart';

const _kHourStart = 8;
const _kHourEnd   = 20;
const _kHourPx    = 64.0;
const _kColHdrH   = 68.0;
const _kTimeColW  = 48.0;
const _kDayColW   = 130.0;

const _kDayAbbr = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

class WeekView extends ConsumerStatefulWidget {
  const WeekView({
    super.key,
    required this.weekStart,
    required this.businessId,
    required this.tenantId,
    required this.onSlotTap,
    required this.onTurnoTap,
  });

  final DateTime weekStart;
  final String businessId;
  final String tenantId;
  final void Function(DateTime slotStart, String? staffId) onSlotTap;
  final void Function(Booking) onTurnoTap;

  @override
  ConsumerState<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends ConsumerState<WeekView> {
  late Timer _timer;
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
    _timer.cancel();
    super.dispose();
  }

  bool _isToday(DateTime day) =>
      day.year == _now.year && day.month == _now.month && day.day == _now.day;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(agendaWeekBookingsProvider((
      businessId: widget.businessId,
      weekStart: widget.weekStart,
    )));
    final staffState = ref.watch(
      businessStaffProvider((tenantId: widget.tenantId, businessId: widget.businessId)),
    );
    final staff = staffState.members.where((s) => s.activo).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    final hoursState = ref.watch(businessHoursProvider((
      tenantId: widget.tenantId,
      businessId: widget.businessId,
    )));

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
        child: Text('Error al cargar', style: GoogleFonts.inter(color: KTokens.inkMuted)),
      ),
      data: (bookings) {
        final days = List.generate(
          7,
          (i) => widget.weekStart.add(Duration(days: i)),
        );
        return _WeekGrid(
          days: days,
          bookings: bookings,
          staff: staff,
          hours: hoursState.hours,
          now: _now,
          isToday: _isToday,
          onSlotTap: widget.onSlotTap,
          onTurnoTap: widget.onTurnoTap,
        );
      },
    );
  }
}

class _WeekGrid extends StatefulWidget {
  const _WeekGrid({
    required this.days,
    required this.bookings,
    required this.staff,
    required this.hours,
    required this.now,
    required this.isToday,
    required this.onSlotTap,
    required this.onTurnoTap,
  });

  final List<DateTime> days;
  final List<Booking> bookings;
  final List<StaffMember> staff;
  final List<BusinessHours> hours;
  final DateTime now;
  final bool Function(DateTime) isToday;
  final void Function(DateTime, String?) onSlotTap;
  final void Function(Booking) onTurnoTap;

  @override
  State<_WeekGrid> createState() => _WeekGridState();
}

class _WeekGridState extends State<_WeekGrid> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitial());
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToInitial() {
    if (!_scrollCtrl.hasClients) return;
    final viewport = _scrollCtrl.position.viewportDimension;
    final hasToday = widget.days.any(widget.isToday);

    double anchorTop;
    if (hasToday) {
      final n = widget.now;
      anchorTop = ((n.hour - _kHourStart) * 60 + n.minute) / 60 * _kHourPx;
    } else {
      // center on 09:00
      anchorTop = (9 - _kHourStart) * _kHourPx;
    }

    final target = (anchorTop - viewport / 2).clamp(0.0, _totalH - viewport);
    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Color _colorFor(String? staffId) {
    if (staffId == null) return KTokens.inkPlaceholder;
    final idx = widget.staff.indexWhere((s) => s.id == staffId);
    if (idx < 0) return KTokens.inkPlaceholder;
    final s = widget.staff[idx];
    if (s.color != null && s.color!.isNotEmpty) {
      try {
        return Color(0xFF000000 | int.parse(s.color!.replaceFirst('#', ''), radix: 16));
      } catch (_) {}
    }
    return KTokens.proPalette[idx % KTokens.proPalette.length];
  }

  List<Booking> _bookingsForDay(DateTime day) => widget.bookings
      .where((b) =>
          b.fechaHoraInicio.year == day.year &&
          b.fechaHoraInicio.month == day.month &&
          b.fechaHoraInicio.day == day.day)
      .toList();

  double _topFor(DateTime dt) {
    final minutesFromStart = (dt.hour - _kHourStart) * 60 + dt.minute;
    return (minutesFromStart / 60) * _kHourPx;
  }

  double get _totalH => (_kHourEnd - _kHourStart) * _kHourPx;

  double get _nowTop {
    final m = (widget.now.hour - _kHourStart) * 60 + widget.now.minute;
    return (m / 60) * _kHourPx;
  }

  double _blockHeight(Booking b) {
    final durationMin = b.fechaHoraFin.difference(b.fechaHoraInicio).inMinutes;
    return (durationMin / 60) * _kHourPx;
  }

  BusinessHours? _hoursForDay(DateTime day) {
    final diaSemana = day.weekday - 1;
    try {
      return widget.hours.firstWhere((h) => h.diaSemana == diaSemana);
    } catch (_) {
      return null;
    }
  }

  int _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  bool _isSlotOpen(DateTime day, int hour) {
    final bh = _hoursForDay(day);
    if (bh == null) return true;
    if (bh.cerrado) return false;
    final slotMin = hour * 60;
    if (bh.apertura != null && slotMin < _parseTimeToMinutes(bh.apertura!)) return false;
    if (bh.cierre != null && slotMin >= _parseTimeToMinutes(bh.cierre!)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final hasToday = widget.days.any(widget.isToday);
    final totalW = _kTimeColW + widget.days.length * _kDayColW;

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftPad = constraints.maxWidth > totalW
            ? (constraints.maxWidth - totalW) / 2
            : 0.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: EdgeInsets.only(left: leftPad),
            child: SizedBox(
              width: totalW,
        child: Column(
          children: [
            // ── Day headers ────────────────────────────────────────────────────
            SizedBox(
              height: _kColHdrH,
              child: Row(
                children: [
                  SizedBox(width: _kTimeColW),
                  ...widget.days.map((day) => _DayColHeader(
                        day: day,
                        isToday: widget.isToday(day),
                        bookingCount: _bookingsForDay(day).length,
                      )),
                ],
              ),
            ),
            Divider(height: 1, color: KTokens.border),
            // ── Timeline ──────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                child: SizedBox(
                  height: _totalH,
                  child: Stack(
                    children: [
                      _HourLines(),
                      _TimeLabels(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: _kTimeColW),
                          ...widget.days.map((day) {
                            final dayBookings = _bookingsForDay(day);
                            return SizedBox(
                              width: _kDayColW,
                              child: Stack(
                                children: [
                                  // Vertical separator
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 1,
                                      color: KTokens.border,
                                    ),
                                  ),
                                  // Today highlight
                                  if (widget.isToday(day))
                                    Positioned.fill(
                                      child: Container(
                                        color: KTokens.accentSoft.withValues(alpha: 0.35),
                                      ),
                                    ),
                                  // Tap-to-create slots
                                  GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapDown: (details) {
                                      final hour = (_kHourStart +
                                              (details.localPosition.dy /
                                                      _kHourPx)
                                                  .floor())
                                          .clamp(_kHourStart, _kHourEnd - 1);
                                      if (!_isSlotOpen(day, hour)) {
                                        final bh = _hoursForDay(day);
                                        final msg = (bh != null && bh.cerrado)
                                            ? 'El negocio está cerrado este día'
                                            : 'Fuera del horario de atención'
                                                ' (${bh?.apertura ?? ''} – ${bh?.cierre ?? ''})';
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(msg),
                                          duration:
                                              const Duration(seconds: 2),
                                        ));
                                        return;
                                      }
                                      final slotStart = DateTime(
                                        day.year,
                                        day.month,
                                        day.day,
                                        hour,
                                      );
                                      widget.onSlotTap(slotStart, null);
                                    },
                                    child: SizedBox(
                                      height: _totalH,
                                      width: double.infinity,
                                    ),
                                  ),
                                  // Booking blocks
                                  ...dayBookings.map((b) => _BookingBlock(
                                        booking: b,
                                        color: _colorFor(b.staffMemberId),
                                        top: _topFor(b.fechaHoraInicio),
                                        height: _blockHeight(b),
                                        onTap: () => widget.onTurnoTap(b),
                                      )),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                      // Now indicator
                      if (hasToday && _nowTop >= 0 && _nowTop <= _totalH)
                        _NowIndicator(top: _nowTop, now: widget.now),
                    ],
                  ),
                ),
              ),
            ),
          ],
            ),
          ),
        ),
      );
      },
    );
  }
}

// ── Day column header ─────────────────────────────────────────────────────────

class _DayColHeader extends StatelessWidget {
  const _DayColHeader({
    required this.day,
    required this.isToday,
    required this.bookingCount,
  });

  final DateTime day;
  final bool isToday;
  final int bookingCount;

  @override
  Widget build(BuildContext context) {
    final abbr = _kDayAbbr[day.weekday - 1];
    return SizedBox(
      width: _kDayColW,
      child: Container(
        decoration: BoxDecoration(
          border: const Border(left: BorderSide(color: Color(0xFFE5E4DF))),
          color: isToday ? KTokens.accentSoft : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              abbr,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: isToday ? KTokens.accent : KTokens.inkSoft,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? KTokens.accent : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : KTokens.ink,
                  ),
                ),
              ),
            ),
            if (bookingCount > 0) ...[
              const SizedBox(height: 1),
              Text(
                '$bookingCount t.',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: isToday ? KTokens.accent : KTokens.inkSoft,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Hour lines ────────────────────────────────────────────────────────────────

class _HourLines extends StatelessWidget {
  const _HourLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_kHourEnd - _kHourStart, (_) {
        return SizedBox(
          height: _kHourPx,
          child: Column(children: [Divider(height: 1, color: KTokens.border), const Spacer()]),
        );
      }),
    );
  }
}

// ── Time labels ───────────────────────────────────────────────────────────────

class _TimeLabels extends StatelessWidget {
  const _TimeLabels();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kTimeColW,
      child: Column(
        children: List.generate(_kHourEnd - _kHourStart, (i) {
          final hour = _kHourStart + i;
          return SizedBox(
            height: _kHourPx,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: KTokens.inkSoft,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Now indicator ─────────────────────────────────────────────────────────────

class _NowIndicator extends StatelessWidget {
  const _NowIndicator({required this.top, required this.now});

  final double top;
  final DateTime now;

  static String _fmt2(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          SizedBox(
            width: _kTimeColW,
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(
                '${_fmt2(now.hour)}:${_fmt2(now.minute)}',
                textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: KTokens.nowIndicator,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: KTokens.nowIndicator,
            ),
          ),
          Expanded(
            child: Container(height: 1.5, color: KTokens.nowIndicator),
          ),
        ],
      ),
    );
  }
}

// ── Booking block ─────────────────────────────────────────────────────────────

class _BookingBlock extends StatelessWidget {
  const _BookingBlock({
    required this.booking,
    required this.color,
    required this.top,
    required this.height,
    required this.onTap,
  });

  final Booking booking;
  final Color color;
  final double top;
  final double height;
  final VoidCallback onTap;

  static String _fmt2(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final minH = height.clamp(24.0, double.infinity);
    final inicio = booking.fechaHoraInicio;
    final fin = booking.fechaHoraFin;
    final timeStr =
        '${_fmt2(inicio.hour)}:${_fmt2(inicio.minute)}–${_fmt2(fin.hour)}:${_fmt2(fin.minute)}';

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      height: minH,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: KTokens.blockBg(color),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: KTokens.blockBorder(color), width: 1.5),
          ),
          padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (minH > 32) ...[
                const SizedBox(height: 1),
                Text(
                  booking.clienteNombre ?? '—',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: KTokens.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
