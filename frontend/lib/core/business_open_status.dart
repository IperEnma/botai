import '../models/agenda/business_hours.dart';

/// Estado actual del local según horarios del negocio (hora local del dispositivo).
class BusinessOpenStatus {
  const BusinessOpenStatus({
    required this.isOpen,
    required this.label,
  });

  final bool isOpen;
  final String label;

  /// Devuelve `null` si no hay horarios configurados o no se puede determinar apertura.
  static BusinessOpenStatus? fromHours(
    List<BusinessHours> hours, {
    DateTime? now,
  }) {
    if (hours.isEmpty) return null;

    final clock = now ?? DateTime.now();
    final todayDow = clock.weekday - 1;
    final nowMinutes = clock.hour * 60 + clock.minute;

    final today = _hoursForDow(hours, todayDow);
    if (today != null && !today.cerrado) {
      final ranges = _rangesForDay(today);
      for (final range in ranges) {
        if (nowMinutes >= range.start && nowMinutes < range.end) {
          return BusinessOpenStatus(
            isOpen: true,
            label: 'Abierto - cierra a las ${_formatMinutes(range.end)}',
          );
        }
      }

      for (final range in ranges) {
        if (nowMinutes < range.start) {
          return BusinessOpenStatus(
            isOpen: false,
            label: 'Cerrado - abre a las ${_formatMinutes(range.start)}',
          );
        }
      }
    }

    final next = _nextOpening(hours, clock);
    if (next == null) return null;

    return BusinessOpenStatus(
      isOpen: false,
      label: 'Cerrado - ${_formatNextOpen(next.date, next.minutes, clock)}',
    );
  }
}

class _DayRange {
  const _DayRange(this.start, this.end);
  final int start;
  final int end;
}

class _NextOpen {
  const _NextOpen(this.date, this.minutes);
  final DateTime date;
  final int minutes;
}

BusinessHours? _hoursForDow(List<BusinessHours> hours, int dow) {
  for (final h in hours) {
    if (h.diaSemana == dow) return h;
  }
  return null;
}

List<_DayRange> _rangesForDay(BusinessHours h) {
  final ranges = <_DayRange>[];
  void add(String? open, String? close) {
    final start = _parseMinutes(open);
    final end = _parseMinutes(close);
    if (start != null && end != null && end > start) {
      ranges.add(_DayRange(start, end));
    }
  }

  add(h.apertura, h.cierre);
  add(h.apertura2, h.cierre2);
  ranges.sort((a, b) => a.start.compareTo(b.start));
  return ranges;
}

int? _parseMinutes(String? hhmm) {
  if (hhmm == null || hhmm.length < 4) return null;
  final parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

String _formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

_NextOpen? _nextOpening(List<BusinessHours> hours, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);

  for (var offset = 0; offset < 8; offset++) {
    final date = today.add(Duration(days: offset));
    final row = _hoursForDow(hours, date.weekday - 1);
    if (row == null || row.cerrado) continue;

    final ranges = _rangesForDay(row);
    if (ranges.isEmpty) continue;

    if (offset == 0) {
      final nowMinutes = now.hour * 60 + now.minute;
      for (final range in ranges) {
        if (nowMinutes < range.start) {
          return _NextOpen(date, range.start);
        }
      }
      continue;
    }

    return _NextOpen(date, ranges.first.start);
  }
  return null;
}

String _formatNextOpen(DateTime date, int minutes, DateTime now) {
  final time = _formatMinutes(minutes);
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final days = target.difference(today).inDays;

  if (days <= 0) return 'abre a las $time';
  if (days == 1) return 'abre mañana a las $time';

  final dow = date.weekday - 1;
  final dayName = BusinessHours.dayNames[dow.clamp(0, 6)].toLowerCase();
  return 'abre el $dayName a las $time';
}
