import '../models/agenda/business_hours.dart';

/// Una línea del resumen de horarios (ej. `Lun – Vie · 09:00 – 18:00`).
class BusinessHoursSummaryLine {
  const BusinessHoursSummaryLine({
    required this.dayLabel,
    required this.schedule,
    required this.isClosed,
  });

  final String dayLabel;
  final String schedule;
  final bool isClosed;

  String get text => '$dayLabel · $schedule';
}

/// Agrupa días consecutivos con el mismo horario en texto legible.
abstract final class BusinessHoursSummary {
  static const _shortDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  static List<BusinessHoursSummaryLine> lines(List<BusinessHours> hours) {
    if (hours.isEmpty) return const [];

    final schedules = List<String>.generate(7, (d) => _scheduleForDay(hours, d));
    final groups = <({int start, int end, String schedule})>[];

    for (var d = 0; d < 7; d++) {
      final schedule = schedules[d];
      if (groups.isNotEmpty &&
          groups.last.schedule == schedule &&
          groups.last.end == d - 1) {
        final last = groups.last;
        groups[groups.length - 1] = (start: last.start, end: d, schedule: schedule);
      } else {
        groups.add((start: d, end: d, schedule: schedule));
      }
    }

    return groups
        .map(
          (g) => BusinessHoursSummaryLine(
            dayLabel: _dayRangeLabel(g.start, g.end),
            schedule: g.schedule,
            isClosed: g.schedule == _closedLabel,
          ),
        )
        .toList();
  }

  static const _closedLabel = 'Cerrado';

  static String _dayRangeLabel(int start, int end) {
    if (start == 0 && end == 6) return 'Todos los días';
    if (start == end) return _shortDays[start];
    return '${_shortDays[start]} – ${_shortDays[end]}';
  }

  static String _scheduleForDay(List<BusinessHours> all, int dow) {
    BusinessHours? row;
    for (final h in all) {
      if (h.diaSemana == dow) {
        row = h;
        break;
      }
    }
    if (row == null || row.cerrado) return _closedLabel;

    bool ok(String? a, String? b) =>
        a != null && a.isNotEmpty && b != null && b.isNotEmpty;

    final ranges = <String>[];
    if (ok(row.apertura, row.cierre)) {
      ranges.add('${row.apertura} – ${row.cierre}');
    }
    if (ok(row.apertura2, row.cierre2)) {
      ranges.add('${row.apertura2} – ${row.cierre2}');
    }
    if (ranges.isEmpty) return _closedLabel;
    return ranges.join(' · ');
  }
}
