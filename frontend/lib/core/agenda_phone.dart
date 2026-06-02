/// Validación y normalización de teléfono para reservas Agenda (público y panel).
bool isValidAgendaPhone(String? raw) {
  return normalizeAgendaPhoneDigits(raw).length >= 7;
}

/// Solo dígitos (sin espacios ni símbolos), alineado con el backend.
String normalizeAgendaPhoneDigits(String? raw) {
  return (raw ?? '').replaceAll(RegExp(r'\D'), '');
}
