import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'BotAI Admin';

  static String _stripTrailingSlash(String value) =>
      value.replaceAll(RegExp(r'/+$'), '');

  /// Host del backend Konecta **sin path** (ej. `http://localhost:8080`).
  ///
  /// Context paths se arman en código:
  /// - Chatbot API → [apiBaseUrl] (`/api`)
  /// - Agenda API → [agendaApiBaseUrl] (`/api/agenda`)
  /// - Uploads → [mediaBaseUrl]/uploads/…
  static String get konectaBaseUrl {
    for (final key in ['KONECTA_BASE_URL', 'PUBLIC_BACKEND_URL']) {
      final v = dotenv.env[key]?.trim();
      if (v != null && v.isNotEmpty) {
        return _stripTrailingSlash(v);
      }
    }
    return _stripTrailingSlash(_konectaBaseFromLegacyApiBaseUrl());
  }

  /// Compat: `API_BASE_URL=http://host:8080/api` → host `http://host:8080`.
  static String _konectaBaseFromLegacyApiBaseUrl() {
    var api = (dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api').trim();
    api = _stripTrailingSlash(api);
    if (api.endsWith('/api')) {
      return api.substring(0, api.length - 4);
    }
    return api;
  }

  /// Base REST del chatbot: `{konectaBaseUrl}/api`.
  static String get apiBaseUrl => '$konectaBaseUrl/api';

  /// Imágenes Agenda (`/uploads/…`) servidas en la raíz del mismo host.
  static String get mediaBaseUrl => konectaBaseUrl;

  /// Alias interno (mismo valor que [konectaBaseUrl]).
  static String get serverBaseUrl => konectaBaseUrl;

  static String get googleClientIdWeb =>
      dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? '';

  static String get googleClientIdAndroid =>
      dotenv.env['GOOGLE_CLIENT_ID_ANDROID'] ?? '';

  static String get googleClientIdIos =>
      dotenv.env['GOOGLE_CLIENT_ID_IOS'] ?? '';

  // ---------------- AGENDA module ----------------

  /// Base Agenda: `{konectaBaseUrl}/api/agenda` salvo override explícito.
  static String get agendaApiBaseUrl {
    final override = dotenv.env['AGENDA_API_BASE_URL']?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return '$konectaBaseUrl/api/agenda';
  }

  /// Si true, el landing /agenda muestra el tile "Plataforma".
  static bool get agendaPlatformAdmin =>
      (dotenv.env['AGENDA_PLATFORM_ADMIN'] ?? 'false').toLowerCase() == 'true';

  /// Tenant id precargado para flujos de tenant admin sin login real (dev only).
  static String? get agendaDefaultTenantId {
    final v = dotenv.env['AGENDA_DEFAULT_TENANT_ID'];
    return (v == null || v.isEmpty) ? null : v;
  }

  /// User id que se manda como X-User-Id mientras no haya módulo de auth final.
  static String? get agendaDefaultUserId {
    final v = dotenv.env['AGENDA_DEFAULT_USER_ID'];
    return (v == null || v.isEmpty) ? null : v;
  }
}
