import 'config.dart';

/// Logo, banner y avatares Agenda: siempre servidos desde el backend actual.
///
/// Las URLs guardadas pueden apuntar a otro host (p. ej. Render/Vercel) mientras
/// los archivos viven en [AppConfig.serverBaseUrl]/uploads/… — reescribimos el path.
String? resolveAgendaMediaUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final u = raw.trim();
  final base = AppConfig.serverBaseUrl;

  const marker = '/uploads/';
  final idx = u.indexOf(marker);
  if (idx >= 0) {
    return '$base${u.substring(idx)}';
  }

  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  if (u.startsWith('/')) return '$base$u';
  return '$base/$u';
}
