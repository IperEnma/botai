import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/booking.dart';
import '../../../../models/agenda/staff_member.dart';
import '../../../../providers/agenda/tenant/agenda_bookings_provider.dart';
import '../../../../providers/agenda/tenant/business_staff_provider.dart';
import '../../register/konecta_tokens.dart';

const _kHourStart = 8;
const _kHourEnd   = 20;
const _kHourPx    = 64.0;
const _kColHdrH   = 64.0;
const _kTimeColW  = 56.0;

class DayView extends ConsumerStatefulWidget {
  const DayView({
    super.key,
    required this.date,
    required this.businessId,
    required this.tenantId,
    this.visibleProId,
    required this.onSlotTap,
    required this.onTurnoTap,
  });

  final DateTime date;
  final String businessId;
  final String tenantId;
  final String? visibleProId;
  final void Function(DateTime slotStart, String? staffId) onSlotTap;
  final void Function(Booking) onTurnoTap;

  @override
  ConsumerState<DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
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

  bool get _isToday {
    final d = widget.date;
    final n = _now;
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(agendaBookingsProvider((
      businessId: widget.businessId,
      day: widget.date,
    )));
    final staffState = ref.watch(
      businessStaffProvider((tenantId: widget.tenantId, businessId: widget.businessId)),
    );

    final allStaff = staffState.members.where((s) => s.activo).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
        child: Text('Error al cargar', style: GoogleFonts.inter(color: KTokens.inkMuted)),
      ),
      data: (bookings) {
        final filtered = widget.visibleProId == null
            ? bookings
            : bookings.where((b) => b.staffMemberId == widget.visibleProId).toList();
        return _DayGrid(
          date: widget.date,
          bookings: filtered,
          staff: allStaff,
          now: _now,
          isToday: _isToday,
          onSlotTap: widget.onSlotTap,
          onTurnoTap: widget.onTurnoTap,
        );
      },
    );
  }
}

class _DayGrid extends StatefulWidget {
  const _DayGrid({
    required this.date,
    required this.bookings,
    required this.staff,
    required this.now,
    required this.isToday,
    required this.onSlotTap,
    required this.onTurnoTap,
  });

  final DateTime date;
  final List<Booking> bookings;
  final List<StaffMember> staff;
  final DateTime now;
  final bool isToday;
  final void Function(DateTime, String?) onSlotTap;
  final void Function(Booking) onTurnoTap;

  @override
  State<_DayGrid> createState() => _DayGridState();
}

class _DayGridState extends State<_DayGrid> {
  final _vertCtrl = ScrollController();
  final _horizCtrl = ScrollController();

  double get _totalH => (_kHourEnd - _kHourStart) * _kHourPx.toDouble();

  double get _nowTop {
    final m = (widget.now.hour - _kHourStart) * 60 + widget.now.minute;
    return (m / 60) * _kHourPx;
  }

  @override
  void initState() {
    super.initState();
    if (widget.isToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    }
  }

  @override
  void didUpdateWidget(_DayGrid old) {
    super.didUpdateWidget(old);
    if (!old.isToday && widget.isToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    }
  }

  void _scrollToNow() {
    if (!_vertCtrl.hasClients) return;
    final target = (_nowTop - 80).clamp(0.0, _totalH);
    _vertCtrl.jumpTo(target);
  }

  @override
  void dispose() {
    _vertCtrl.dispose();
    _horizCtrl.dispose();
    super.dispose();
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

  List<Booking> _bookingsFor(String? staffId) {
    if (staffId == null) {
      return widget.bookings.where((b) => b.staffMemberId == null).toList();
    }
    return widget.bookings.where((b) => b.staffMemberId == staffId).toList();
  }

  double _topFor(DateTime dt) {
    final minutesFromStart = (dt.hour - _kHourStart) * 60 + dt.minute;
    return (minutesFromStart / 60) * _kHourPx;
  }

  double _blockHeight(Booking b) {
    final durationMin = b.fechaHoraFin.difference(b.fechaHoraInicio).inMinutes;
    return (durationMin / 60) * _kHourPx;
  }

  @override
  Widget build(BuildContext context) {
    final unassigned = _bookingsFor(null);
    final columns = <_Col>[
      for (final s in widget.staff) _Col(staffId: s.id, member: s),
      if (unassigned.isNotEmpty) _Col(staffId: null, member: null),
    ];

    if (columns.isEmpty && widget.bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available_outlined, size: 40, color: KTokens.inkPlaceholder),
            const SizedBox(height: 12),
            Text(
              'Sin turnos para este día',
              style: GoogleFonts.inter(fontSize: 14, color: KTokens.inkMuted),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _horizCtrl,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _kTimeColW + (columns.isEmpty ? 200 : columns.length * 180.0),
        child: Column(
          children: [
            // ── Column headers ────────────────────────────────────────────────
            SizedBox(
              height: _kColHdrH,
              child: Row(
                children: [
                  SizedBox(width: _kTimeColW),
                  ...columns.map((col) => _ColHeader(
                        col: col,
                        color: _colorFor(col.staffId),
                        bookingCount: _bookingsFor(col.staffId).length,
                      )),
                ],
              ),
            ),
            Divider(height: 1, color: KTokens.border),
            // ── Timeline ──────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _vertCtrl,
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
                          ...columns.map((col) {
                            final colBookings = _bookingsFor(col.staffId);
                            final color = _colorFor(col.staffId);
                            return Expanded(
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapDown: (details) {
                                      final hour = _kHourStart +
                                          (details.localPosition.dy / _kHourPx)
                                              .floor();
                                      final slotStart = DateTime(
                                        widget.date.year,
                                        widget.date.month,
                                        widget.date.day,
                                        hour.clamp(_kHourStart, _kHourEnd - 1),
                                      );
                                      widget.onSlotTap(slotStart, col.staffId);
                                    },
                                    child: SizedBox(
                                      height: _totalH,
                                      width: double.infinity,
                                    ),
                                  ),
                                  ...colBookings.map((b) => _BookingBlock(
                                        booking: b,
                                        color: color,
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
                      if (widget.isToday && _nowTop >= 0 && _nowTop <= _totalH)
                        _NowIndicator(top: _nowTop, now: widget.now),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Col {
  const _Col({required this.staffId, required this.member});
  final String? staffId;
  final StaffMember? member;
}

class _ColHeader extends StatelessWidget {
  const _ColHeader({
    required this.col,
    required this.color,
    required this.bookingCount,
  });

  final _Col col;
  final Color color;
  final int bookingCount;

  String get _initials {
    final name = col.member?.nombre ?? 'Sin asignar';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KTokens.blockBg(color),
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    col.member?.nombre ?? 'Sin asignar',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: KTokens.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$bookingCount turno${bookingCount != 1 ? 's' : ''}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: KTokens.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HourLines extends StatelessWidget {
  const _HourLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_kHourEnd - _kHourStart, (i) {
        return SizedBox(
          height: _kHourPx,
          child: Column(
            children: [
              Divider(height: 1, color: KTokens.border),
              const Spacer(),
            ],
          ),
        );
      }),
    );
  }
}

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
            child: Container(
              height: 1.5,
              color: KTokens.nowIndicator,
            ),
          ),
        ],
      ),
    );
  }
}

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
        '${_fmt2(inicio.hour)}:${_fmt2(inicio.minute)} – ${_fmt2(fin.hour)}:${_fmt2(fin.minute)}';

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
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: KTokens.blockBorder(color), width: 1.5),
          ),
          padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
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
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: KTokens.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (minH > 48)
                Text(
                  booking.servicioNombre,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: KTokens.inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
