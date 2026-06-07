import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'BotAI Admin';

  static String get apiBaseUrl =>
      (dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api').trim();

  /// Raíz del backend (sin sufijo /api).
  static String get serverBaseUrl {
    var api = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (api.endsWith('/api')) {
      api = api.substring(0, api.length - 4);
    }
    return api.replaceAll(RegExp(r'/+$'), '');
  }

  /// Host público para `/uploads/**` (logo, banner, avatares).
  /// Prioriza `PUBLIC_BACKEND_URL`; si no, [serverBaseUrl].
  static String get mediaBaseUrl {
    final override = dotenv.env['PUBLIC_BACKEND_URL']?.trim();
    if (override != null && override.isNotEmpty) {
      return override.replaceAll(RegExp(r'/+$'), '');
    }
    return serverBaseUrl;
  }

  static String get googleClientIdWeb =>
      dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? '';

  static String get googleClientIdAndroid =>
      dotenv.env['GOOGLE_CLIENT_ID_ANDROID'] ?? '';

  static String get googleClientIdIos =>
      dotenv.env['GOOGLE_CLIENT_ID_IOS'] ?? '';

  // ---------------- AGENDA module ----------------

  /// Base URL para los endpoints /api/agenda/**. Si la var está vacía,
  /// se deriva de [apiBaseUrl] agregando "/agenda".
  static String get agendaApiBaseUrl {
    final override = dotenv.env['AGENDA_API_BASE_URL'];
    if (override != null && override.trim().isNotEmpty) {
      return override.trim();
    }
    return '$apiBaseUrl/agenda';
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
