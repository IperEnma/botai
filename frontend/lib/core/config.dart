import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'BotAI Admin';

  static const _localHosts = {'localhost', '127.0.0.1', '0.0.0.0'};

  static String _stripTrailingSlash(String value) =>
      value.replaceAll(RegExp(r'/+$'), '');

  static String _configuredKonectaBaseUrl() =>
      dotenv.env['KONECTA_BASE_URL']?.trim() ?? 'http://localhost:8080';

  /// Resuelve el host del backend según desde dónde se abre la app (web/LAN/HTTPS).
  static String _resolveKonectaBaseUrl(String configured) {
    final uri = Uri.parse(configured);

    if (kIsWeb) {
      final page = Uri.base;

      // Dev: frontend por IP (ej. celular en la red) pero .env dice localhost:8080
      if (_localHosts.contains(uri.host) &&
          page.host.isNotEmpty &&
          !_localHosts.contains(page.host)) {
        return Uri(
          scheme: page.scheme,
          host: page.host,
          port: uri.hasPort ? uri.port : 8080,
        ).toString();
      }

      // Prod: evitar mixed content (página https + imágenes http)
      if (page.scheme == 'https' && uri.scheme == 'http') {
        return uri.replace(scheme: 'https').toString();
      }
    }

    return configured;
  }

  /// Host Konecta sin path. Variable única: `KONECTA_BASE_URL`.
  ///
  /// - Chatbot API → [apiBaseUrl] = `{KONECTA_BASE_URL}/api`
  /// - Agenda API → [agendaApiBaseUrl] = `{KONECTA_BASE_URL}/api/agenda`
  /// - Uploads → `{KONECTA_BASE_URL}/uploads/…`
  static String get konectaBaseUrl => _stripTrailingSlash(
        _resolveKonectaBaseUrl(_configuredKonectaBaseUrl()),
      );

  static String get apiBaseUrl => '$konectaBaseUrl/api';

  static String get mediaBaseUrl => konectaBaseUrl;

  static String get serverBaseUrl => konectaBaseUrl;

  static String get agendaApiBaseUrl => '$konectaBaseUrl/api/agenda';

  static String get googleClientIdWeb =>
      dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? '';

  static String get googleClientIdAndroid =>
      dotenv.env['GOOGLE_CLIENT_ID_ANDROID'] ?? '';

  static String get googleClientIdIos =>
      dotenv.env['GOOGLE_CLIENT_ID_IOS'] ?? '';

  static bool get agendaPlatformAdmin =>
      (dotenv.env['AGENDA_PLATFORM_ADMIN'] ?? 'false').toLowerCase() == 'true';

  static String? get agendaDefaultTenantId {
    final v = dotenv.env['AGENDA_DEFAULT_TENANT_ID'];
    return (v == null || v.isEmpty) ? null : v;
  }

  static String? get agendaDefaultUserId {
    final v = dotenv.env['AGENDA_DEFAULT_USER_ID'];
    return (v == null || v.isEmpty) ? null : v;
  }

  /// URL pública del frontend para links compartidos (p. ej. app en Vercel).
  /// Opcional: si no está, en web se usa [Uri.base.origin].
  static String? get publicAppBaseUrl {
    final v = dotenv.env['PUBLIC_APP_BASE_URL']?.trim();
    if (v == null || v.isEmpty) return null;
    return _stripTrailingSlash(v);
  }
}
