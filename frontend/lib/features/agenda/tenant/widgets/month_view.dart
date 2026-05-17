import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/booking.dart';
import '../../../../models/agenda/staff_member.dart';
import '../../../../providers/agenda/tenant/agenda_month_provider.dart';
import '../../../../providers/agenda/tenant/business_staff_provider.dart';
import '../../register/konecta_tokens.dart';

class MonthView extends ConsumerWidget {
  const MonthView({
    super.key,
    required this.date,
    required this.businessId,
    required this.tenantId,
    required this.onDayTap,
    this.selectedProId,
  });

  final DateTime date;
  final String businessId;
  final String tenantId;
  final void Function(DateTime) onDayTap;
  final String? selectedProId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(agendaMonthBookingsProvider((
      businessId: businessId,
      year: date.year,
      month: date.month,
    )));
    final staffAsync = ref.watch(
      businessStaffProvider((tenantId: tenantId, businessId: businessId)),
    );

    final staff = staffAsync.members;

    return bookingsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error al cargar turnos',
          style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
        ),
      ),
      data: (bookings) {
        final filtered = selectedProId == null
            ? bookings
            : bookings.where((b) => b.staffMemberId == selectedProId).toList();
        return _MonthGrid(
          date: date,
          bookings: filtered,
          staff: staff,
          onDayTap: onDayTap,
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.date,
    required this.bookings,
    required this.staff,
    required this.onDayTap,
  });

  final DateTime date;
  final List<Booking> bookings;
  final List<StaffMember> staff;
  final void Function(DateTime) onDayTap;

  static const _weekDays = ['DOM', 'LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB'];

  /// Returns the color for a staff member by their sorted index.
  Color _colorFor(String? staffId) {
    if (staffId == null) return KTokens.inkPlaceholder;
    final idx = staff.indexWhere((s) => s.id == staffId);
    if (idx < 0) return KTokens.inkPlaceholder;
    return KTokens.proPalette[idx % KTokens.proPalette.length];
  }

  List<DateTime> _buildCalendarDays() {
    final first = DateTime(date.year, date.month, 1);
    final last = DateTime(date.year, date.month + 1, 0);
    // weekday: Mon=1 ... Sun=7; we need Sun=0 ... Sat=6
    final startOffset = first.weekday % 7;
    final endOffset = (6 - last.weekday % 7);
    final days = <DateTime>[];
    for (var i = startOffset; i > 0; i--) {
      days.add(first.subtract(Duration(days: i)));
    }
    for (var d = first;
        !d.isAfter(last);
        d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    for (var i = 1; i <= endOffset; i++) {
      days.add(last.add(Duration(days: i)));
    }
    return days;
  }

  Map<String, List<Booking>> _groupByDay() {
    final map = <String, List<Booking>>{};
    for (final b in bookings) {
      final key = _dayKey(b.fechaHoraInicio);
      map.putIfAbsent(key, () => []).add(b);
    }
    return map;
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays();
    final byDay = _groupByDay();
    final today = DateTime.now();
    final todayKey = _dayKey(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Day-of-week header
        Row(
          children: _weekDays
              .map((d) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      child: Text(
                        d,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: KTokens.inkSoft,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        Divider(height: 1, color: KTokens.border),
        // Grid
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final rowCount = (days.length / 7).ceil();
            final cellH = constraints.maxHeight / rowCount;
            return Column(
              children: List.generate(rowCount, (row) {
                return Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(7, (col) {
                      final idx = row * 7 + col;
                      if (idx >= days.length) return const Expanded(child: SizedBox());
                      final day = days[idx];
                      final isCurrentMonth = day.month == date.month;
                      final key = _dayKey(day);
                      final isToday = key == todayKey;
                      final dayBookings = byDay[key] ?? [];
                      return Expanded(
                        child: _MonthCell(
                          day: day,
                          isCurrentMonth: isCurrentMonth,
                          isToday: isToday,
                          bookings: dayBookings,
                          colorFor: _colorFor,
                          cellHeight: cellH,
                          onTap: () => onDayTap(day),
                        ),
                      );
                    }),
                  ),
                );
              }),
            );
          }),
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.bookings,
    required this.colorFor,
    required this.cellHeight,
    required this.onTap,
  });

  final DateTime day;
  final bool isCurrentMonth;
  final bool isToday;
  final List<Booking> bookings;
  final Color Function(String?) colorFor;
  final double cellHeight;
  final VoidCallback onTap;

  static String _fmt2(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    const maxChips = 3;
    final shown = bookings.take(maxChips).toList();
    final overflow = bookings.length - maxChips;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentMonth ? null : KTokens.bg.withValues(alpha: 0.6),
          border: Border(
            right: BorderSide(color: KTokens.border),
            bottom: BorderSide(color: KTokens.border),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day number
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday ? KTokens.accent : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday
                          ? Colors.white
                          : isCurrentMonth
                              ? KTokens.ink
                              : KTokens.inkPlaceholder,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Mini chips
            ...shown.map((b) {
              final color = colorFor(b.staffMemberId);
              final hora =
                  '${_fmt2(b.fechaHoraInicio.hour)}:${_fmt2(b.fechaHoraInicio.minute)}';
              final short = b.clienteNombre?.split(' ').first ?? '—';
              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: KTokens.blockBg(color),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$hora $short',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
            if (overflow > 0)
              Text(
                '+ $overflow más',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: KTokens.inkSoft,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
