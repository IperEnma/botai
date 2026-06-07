import 'config.dart';

/// Logo, banner y avatares Agenda: siempre servidos desde el backend actual.
///
/// Prioriza `/api/agenda/public/media/…` (misma base que la API pública).
/// Fallback: `{KONECTA_BASE_URL}/uploads/…` directo.
String? resolveAgendaMediaUrl(String? raw) {
  if (raw == null) return null;
  final u = raw.trim();
  if (u.isEmpty) return null;
  if (u.startsWith('data:') || u.startsWith('blob:')) return null;

  final uploadPath = _extractUploadPath(u);
  if (uploadPath != null) {
    final relative = uploadPath.substring('/uploads/'.length);
    return '${AppConfig.agendaApiBaseUrl}/public/media/$relative';
  }

  if (u.startsWith('http://') || u.startsWith('https://')) {
    return u;
  }
  if (u.startsWith('/')) {
    return '${AppConfig.mediaBaseUrl}$u';
  }
  if (u.startsWith('uploads/')) {
    return '${AppConfig.mediaBaseUrl}/$u';
  }
  return '${AppConfig.mediaBaseUrl}/$u';
}

/// Devuelve `/uploads/…` si [raw] apunta a un archivo subido de Agenda.
String? _extractUploadPath(String raw) {
  const marker = '/uploads/';
  final idx = raw.indexOf(marker);
  if (idx >= 0) {
    return raw.substring(idx);
  }

  const apiMarker = '/api/agenda/public/media/';
  final apiIdx = raw.indexOf(apiMarker);
  if (apiIdx >= 0) {
    final relative = raw.substring(apiIdx + apiMarker.length);
    return '/uploads/$relative';
  }

  const legacyApiMarker = '/api/uploads/';
  final legacyIdx = raw.indexOf(legacyApiMarker);
  if (legacyIdx >= 0) {
    return raw.substring(legacyIdx + 4);
  }

  return null;
}
