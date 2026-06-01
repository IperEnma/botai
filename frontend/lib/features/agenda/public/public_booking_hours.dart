import '../../../models/agenda/business_hours.dart';

/// Indica si el negocio atiende en [day] según horarios configurados.
///
/// Si no hay horarios cargados, se permite elegir el día (el backend devolverá
/// lista vacía de turnos hasta que el negocio configure horarios).
bool isPublicBookingDayOpen(DateTime day, List<BusinessHours> hours) {
  if (hours.isEmpty) return true;
  final dow = day.weekday - 1;
  BusinessHours? row;
  for (final h in hours) {
    if (h.diaSemana == dow) {
      row = h;
      break;
    }
  }
  if (row == null) return false;
  if (row.cerrado) return false;
  bool hasRange(String? a, String? c) =>
      a != null && a.isNotEmpty && c != null && c.isNotEmpty;
  return hasRange(row.apertura, row.cierre) ||
      hasRange(row.apertura2, row.cierre2);
}
