import 'dart:convert';

/// Normaliza lo que guardamos o mandamos como Bearer para el Resource Server (JWT de Google).
///
/// Evita: comillas JSON, prefijo `Bearer ` duplicado, espacios — causas de "Malformed token" en Spring.
String? normalizeGoogleBearer(String? raw) {
  if (raw == null) return null;
  var t = raw.trim();
  if (t.isEmpty) return null;
  while (t.toLowerCase().startsWith('bearer ')) {
    t = t.substring(7).trim();
  }
  if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
    try {
      final decoded = jsonDecode(t);
      if (decoded is String) t = decoded.trim();
    } catch (_) {
      t = t.substring(1, t.length - 1).trim();
    }
  }
  return t.isEmpty ? null : t;
}

/// Tres segmentos y header JWT decodificable como objeto JSON (no un string suelto).
bool isGoogleIdJwtShape(String token) {
  final t = normalizeGoogleBearer(token);
  if (t == null) return false;
  final parts = t.split('.');
  if (parts.length != 3) return false;
  if (parts.any((p) => p.isEmpty)) return false;
  try {
    final padded = _base64UrlPad(parts[0]);
    final hdr = utf8.decode(base64Url.decode(padded));
    final o = jsonDecode(hdr);
    return o is Map<String, dynamic>;
  } catch (_) {
    return false;
  }
}

String _base64UrlPad(String s) {
  final m = s.length % 4;
  if (m == 0) return s;
  return s + '=' * (4 - m);
}
