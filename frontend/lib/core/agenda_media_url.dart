import 'config.dart';

/// Logo, banner y avatares Agenda: siempre servidos desde el backend actual.
///
/// Prioriza `/api/agenda/public/media/…` (misma base que la API pública).
/// Fallback: `{KONECTA_BASE_URL}/uploads/…` directo.
///
/// Texto libre (p. ej. dirección postal) **no** es media → devuelve null.
String? resolveAgendaMediaUrl(String? raw) {
  if (raw == null) return null;
  final u = raw.trim();
  if (u.isEmpty) return null;

  final uploadPath = _extractUploadPath(u);
  if (uploadPath != null) {
    final relative = uploadPath.substring('/uploads/'.length);
    return '${AppConfig.agendaApiBaseUrl}/public/media/$relative';
  }

  if (u.startsWith('http://') || u.startsWith('https://')) {
    return _extractUploadPath(u) != null ? u : null;
  }

  if (u.startsWith('/uploads/')) {
    final relative = u.substring('/uploads/'.length);
    return '${AppConfig.agendaApiBaseUrl}/public/media/$relative';
  }
  if (u.startsWith('uploads/')) {
    return '${AppConfig.agendaApiBaseUrl}/public/media/${u.substring('uploads/'.length)}';
  }

  return null;
}

/// True si [raw] parece URL/path de imagen subida de Agenda (no dirección ni texto libre).
bool isAgendaMediaUrl(String? raw) {
  if (raw == null) return false;
  final u = raw.trim();
  if (u.isEmpty) return false;
  if (_extractUploadPath(u) != null) return true;
  if (u.startsWith('/uploads/') || u.startsWith('uploads/')) return true;
  return false;
}

/// Devuelve [raw] solo si es media válida; si no, null (evita GET a direcciones en banner/logo).
String? sanitizeAgendaMediaUrl(String? raw) =>
    isAgendaMediaUrl(raw) ? raw!.trim() : null;

/// Dirección postal: rechaza paths `/uploads/…` guardados por error en [direccion].
String? sanitizeBusinessDireccion(String? raw) {
  if (raw == null) return null;
  final v = raw.trim();
  if (v.isEmpty || isAgendaMediaUrl(v)) return null;
  return v;
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
