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

Map<String, dynamic>? _decodeJwtPart(String part) {
  try {
    final json = utf8.decode(base64Url.decode(_base64UrlPad(part)));
    final o = jsonDecode(json);
    return o is Map<String, dynamic> ? o : null;
  } catch (_) {
    return null;
  }
}

/// Tres segmentos y header JWT decodificable como objeto JSON (no un string suelto).
bool isGoogleIdJwtShape(String token) {
  final t = normalizeGoogleBearer(token);
  if (t == null) return false;
  final parts = t.split('.');
  if (parts.length != 3) return false;
  if (parts.any((p) => p.isEmpty)) return false;
  return _decodeJwtPart(parts[0]) != null;
}

/// ID token de Google usable contra el backend (RS256, issuer Google, no vencido).
bool isUsableGoogleIdToken(
  String token, {
  DateTime? now,
  Duration clockSkew = const Duration(seconds: 60),
}) {
  final t = normalizeGoogleBearer(token);
  if (t == null || !isGoogleIdJwtShape(t)) return false;

  final parts = t.split('.');
  final header = _decodeJwtPart(parts[0]);
  final payload = _decodeJwtPart(parts[1]);
  if (header == null || payload == null) return false;

  if (header['alg']?.toString() != 'RS256') return false;

  final iss = payload['iss']?.toString();
  if (iss != 'https://accounts.google.com' && iss != 'accounts.google.com') {
    return false;
  }

  final exp = payload['exp'];
  if (exp is num) {
    final expiresAt =
        DateTime.fromMillisecondsSinceEpoch((exp * 1000).round(), isUtc: true);
    final effectiveNow = (now ?? DateTime.now()).toUtc();
    if (effectiveNow.isAfter(expiresAt.add(clockSkew))) return false;
  }

  return true;
}

String _base64UrlPad(String s) {
  final m = s.length % 4;
  if (m == 0) return s;
  return s + '=' * (4 - m);
}
