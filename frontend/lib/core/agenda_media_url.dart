import 'config.dart';

/// Logo, banner y avatares Agenda: siempre servidos desde el backend actual.
///
/// Las URLs guardadas pueden apuntar a otro host (p. ej. Render/Vercel) mientras
/// los archivos viven en [AppConfig.mediaBaseUrl]/uploads/… — reescribimos el path.
String? resolveAgendaMediaUrl(String? raw) {
  if (raw == null) return null;
  final u = raw.trim();
  if (u.isEmpty) return null;
  if (u.startsWith('data:') || u.startsWith('blob:')) return null;

  final base = AppConfig.mediaBaseUrl;
  const marker = '/uploads/';

  final idx = u.indexOf(marker);
  if (idx >= 0) {
    final path = u.substring(idx);
    return '$base$path';
  }

  // Algunos registros legacy usan /api/uploads/…
  const apiMarker = '/api/uploads/';
  final apiIdx = u.indexOf(apiMarker);
  if (apiIdx >= 0) {
    final path = u.substring(apiIdx + 4); // quita "/api"
    return '$base$path';
  }

  if (u.startsWith('http://') || u.startsWith('https://')) {
    return u;
  }
  if (u.startsWith('/')) {
    return '$base$u';
  }
  if (u.startsWith('uploads/')) {
    return '$base/$u';
  }
  return '$base/$u';
}
