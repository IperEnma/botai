import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/auth_bearer_token.dart';
import '../core/config.dart';
import '../models/user.dart';
import '../models/bot.dart';
import '../models/menu.dart';
import '../models/knowledge.dart';
import '../models/appointment.dart';
import '../models/whatsapp_webhook_setup.dart';

class ApiService {
  final String baseUrl;
  String? _accessToken;
  Future<String?> Function()? _refreshAccessToken;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  void setAccessToken(String? token) {
    _accessToken = normalizeGoogleBearer(token);
  }

  /// Si el backend responde 401 (JWT de Google vencido), se llama para renovar `id_token` sin UI y reintentar una vez.
  void setRefreshAccessTokenCallback(Future<String?> Function()? cb) =>
      _refreshAccessToken = cb;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<http.Response> _with401Retry(Future<http.Response> Function() exec) async {
    var response = await exec();
    if (response.statusCode == 401 && _refreshAccessToken != null) {
      final newToken = await _refreshAccessToken!();
      if (newToken != null && newToken.trim().isNotEmpty) {
        setAccessToken(newToken);
        response = await exec();
      }
    }
    return response;
  }

  Future<User> authenticateWithGoogle(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error authenticating: ${response.body}');
    }
  }

  // Bot CRUD
  Future<List<Bot>> getBots() async {
    final response = await _with401Retry(() => http.get(
          Uri.parse('$baseUrl/bots'),
          headers: _headers,
        ));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((b) => Bot.fromJson(b)).toList();
    } else {
      throw Exception('Error fetching bots: ${response.body}');
    }
  }

  Future<Bot> createBot(Bot bot) async {
    final response = await _with401Retry(() => http.post(
          Uri.parse('$baseUrl/bots'),
          headers: _headers,
          body: jsonEncode(bot.toJson()),
        ));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Bot.fromJson(jsonDecode(response.body));
    } else {
      final msg = _tryParseErrorMessage(response.body);
      throw Exception(msg ?? 'Error creating bot: ${response.body}');
    }
  }

  static String? _tryParseErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final m = decoded['message']?.toString();
        if (m != null && m.isNotEmpty) return m;
        final e = decoded['error']?.toString();
        if (e != null && e.isNotEmpty) return e;
      }
    } catch (_) {}
    return null;
  }

  Future<Bot> updateBot(Bot bot, {String? whatsappAccessTokenPlain}) async {
    final body = bot.toJson();
    body.remove('whatsappAccessToken');
    if (whatsappAccessTokenPlain != null &&
        whatsappAccessTokenPlain.trim().isNotEmpty) {
      body['whatsappAccessToken'] = whatsappAccessTokenPlain.trim();
    }
    final response = await _with401Retry(() => http.put(
          Uri.parse('$baseUrl/bots/${bot.id}'),
          headers: _headers,
          body: jsonEncode(body),
        ));

    if (response.statusCode == 200) {
      return Bot.fromJson(jsonDecode(response.body));
    } else {
      final parsed = _tryParseErrorMessage(response.body);
      throw Exception(parsed ?? 'Error updating bot (${response.statusCode})');
    }
  }

  Future<void> deleteBot(String botId) async {
    final response = await _with401Retry(() => http.delete(
          Uri.parse('$baseUrl/bots/$botId'),
          headers: _headers,
        ));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error deleting bot: ${response.body}');
    }
  }

  Future<WhatsAppWebhookSetupInfo> getWhatsAppWebhookSetup(String botId) async {
    final response = await _with401Retry(() => http.get(
          Uri.parse('$baseUrl/bots/$botId/whatsapp-webhook-setup'),
          headers: _headers,
        ));

    if (response.statusCode == 200) {
      return WhatsAppWebhookSetupInfo.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error fetching WhatsApp webhook setup: ${response.body}');
  }

  // Menu CRUD
  Future<List<Menu>> getMenus(String tenantId) async {
    final response = await _with401Retry(() => http.get(
          Uri.parse('$baseUrl/tenants/$tenantId/menus'),
          headers: _headers,
        ));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((m) => Menu.fromJson(m)).toList();
    } else {
      throw Exception('Error fetching menus: ${response.body}');
    }
  }

  Future<Menu> createMenu(Menu menu) async {
    final response = await _with401Retry(() => http.post(
          Uri.parse('$baseUrl/tenants/${menu.tenantId}/menus'),
          headers: _headers,
          body: jsonEncode(menu.toJson()),
        ));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Menu.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error creating menu: ${response.body}');
    }
  }

  Future<Menu> updateMenu(Menu menu) async {
    final response = await _with401Retry(() => http.put(
          Uri.parse('$baseUrl/tenants/${menu.tenantId}/menus/${menu.id}'),
          headers: _headers,
          body: jsonEncode(menu.toJson()),
        ));

    if (response.statusCode == 200) {
      return Menu.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error updating menu: ${response.body}');
    }
  }

  Future<void> deleteMenu(String tenantId, String menuId) async {
    final response = await _with401Retry(() => http.delete(
          Uri.parse('$baseUrl/tenants/$tenantId/menus/$menuId'),
          headers: _headers,
        ));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error deleting menu: ${response.body}');
    }
  }

  // Citas / Agenda
  Future<List<Appointment>> getAppointments(String tenantId,
      {String? from, String? to, bool includeCancelled = false, String? customerDocument}) async {
    var uri = Uri.parse('$baseUrl/tenants/$tenantId/appointments');
    final qp = <String, String>{...uri.queryParameters};
    if (from != null && from.isNotEmpty) qp['from'] = from;
    if (to != null && to.isNotEmpty) qp['to'] = to;
    qp['includeCancelled'] = includeCancelled ? 'true' : 'false';
    if (customerDocument != null && customerDocument.isNotEmpty) {
      qp['customerDocument'] = customerDocument;
    }
    uri = uri.replace(queryParameters: qp);
    final response = await _with401Retry(() => http.get(uri, headers: _headers));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Appointment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    throw Exception('Error fetching appointments: ${response.body}');
  }

  Future<Appointment> createAppointment(String tenantId, Map<String, dynamic> body) async {
    final response = await _with401Retry(() => http.post(
          Uri.parse('$baseUrl/tenants/$tenantId/appointments'),
          headers: _headers,
          body: jsonEncode(body),
        ));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Appointment.fromJson(Map<String, dynamic>.from(jsonDecode(response.body) as Map));
    }
    throw Exception('Error creating appointment: ${response.body}');
  }

  // Knowledge CRUD (Capa 2 - RAG)
  Future<List<KnowledgeChunk>> getKnowledge(String tenantId) async {
    final response = await _with401Retry(() => http.get(
          Uri.parse('$baseUrl/tenants/$tenantId/knowledge'),
          headers: _headers,
        ));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((k) => KnowledgeChunk.fromJson(k)).toList();
    } else {
      throw Exception('Error fetching knowledge: ${response.body}');
    }
  }

  Future<KnowledgeChunk> createKnowledge(KnowledgeChunk chunk) async {
    final response = await _with401Retry(() => http.post(
          Uri.parse('$baseUrl/tenants/${chunk.tenantId}/knowledge'),
          headers: _headers,
          body: jsonEncode(chunk.toJson()),
        ));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return KnowledgeChunk.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error creating knowledge: ${response.body}');
    }
  }

  Future<KnowledgeChunk> updateKnowledge(KnowledgeChunk chunk) async {
    final response = await _with401Retry(() => http.put(
          Uri.parse('$baseUrl/tenants/${chunk.tenantId}/knowledge/${chunk.id}'),
          headers: _headers,
          body: jsonEncode(chunk.toJson()),
        ));

    if (response.statusCode == 200) {
      return KnowledgeChunk.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error updating knowledge: ${response.body}');
    }
  }

  Future<void> deleteKnowledge(String tenantId, String knowledgeId) async {
    final response = await _with401Retry(() => http.delete(
          Uri.parse('$baseUrl/tenants/$tenantId/knowledge/$knowledgeId'),
          headers: _headers,
        ));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error deleting knowledge: ${response.body}');
    }
  }

  // Menu Triggers
  Future<List<MenuTrigger>> getMenuTriggers(String tenantId) async {
    final response = await _with401Retry(() => http.get(
          Uri.parse('$baseUrl/tenants/$tenantId/triggers'),
          headers: _headers,
        ));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((t) => MenuTrigger.fromJson(t)).toList();
    } else {
      throw Exception('Error fetching triggers: ${response.body}');
    }
  }

  Future<MenuTrigger> createMenuTrigger(MenuTrigger trigger) async {
    final response = await _with401Retry(() => http.post(
          Uri.parse('$baseUrl/tenants/${trigger.tenantId}/triggers'),
          headers: _headers,
          body: jsonEncode(trigger.toJson()),
        ));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return MenuTrigger.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error creating trigger: ${response.body}');
    }
  }

  Future<void> deleteMenuTrigger(String tenantId, String triggerId) async {
    final response = await _with401Retry(() => http.delete(
          Uri.parse('$baseUrl/tenants/$tenantId/triggers/$triggerId'),
          headers: _headers,
        ));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error deleting trigger: ${response.body}');
    }
  }
}
