import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../models/user.dart';
import '../models/bot.dart';
import '../models/menu.dart';
import '../models/knowledge.dart';

class ApiService {
  final String baseUrl;
  String? _accessToken;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

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
    final response = await http.get(
      Uri.parse('$baseUrl/bots'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((b) => Bot.fromJson(b)).toList();
    } else {
      throw Exception('Error fetching bots: ${response.body}');
    }
  }

  Future<Bot> createBot(Bot bot) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bots'),
      headers: _headers,
      body: jsonEncode(bot.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Bot.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error creating bot: ${response.body}');
    }
  }

  Future<Bot> updateBot(Bot bot) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bots/${bot.id}'),
      headers: _headers,
      body: jsonEncode(bot.toJson()),
    );

    if (response.statusCode == 200) {
      return Bot.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error updating bot: ${response.body}');
    }
  }

  Future<void> deleteBot(String botId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/bots/$botId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error deleting bot: ${response.body}');
    }
  }

  // Menu CRUD
  Future<List<Menu>> getMenus(String tenantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tenants/$tenantId/menus'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((m) => Menu.fromJson(m)).toList();
    } else {
      throw Exception('Error fetching menus: ${response.body}');
    }
  }

  Future<Menu> createMenu(Menu menu) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tenants/${menu.tenantId}/menus'),
      headers: _headers,
      body: jsonEncode(menu.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Menu.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error creating menu: ${response.body}');
    }
  }

  Future<Menu> updateMenu(Menu menu) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tenants/${menu.tenantId}/menus/${menu.id}'),
      headers: _headers,
      body: jsonEncode(menu.toJson()),
    );

    if (response.statusCode == 200) {
      return Menu.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error updating menu: ${response.body}');
    }
  }

  Future<void> deleteMenu(String tenantId, String menuId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tenants/$tenantId/menus/$menuId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error deleting menu: ${response.body}');
    }
  }

  // Knowledge CRUD (Capa 2 - RAG)
  Future<List<KnowledgeChunk>> getKnowledge(String tenantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tenants/$tenantId/knowledge'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((k) => KnowledgeChunk.fromJson(k)).toList();
    } else {
      throw Exception('Error fetching knowledge: ${response.body}');
    }
  }

  Future<KnowledgeChunk> createKnowledge(KnowledgeChunk chunk) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tenants/${chunk.tenantId}/knowledge'),
      headers: _headers,
      body: jsonEncode(chunk.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return KnowledgeChunk.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error creating knowledge: ${response.body}');
    }
  }

  Future<KnowledgeChunk> updateKnowledge(KnowledgeChunk chunk) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tenants/${chunk.tenantId}/knowledge/${chunk.id}'),
      headers: _headers,
      body: jsonEncode(chunk.toJson()),
    );

    if (response.statusCode == 200) {
      return KnowledgeChunk.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error updating knowledge: ${response.body}');
    }
  }

  Future<void> deleteKnowledge(String tenantId, String knowledgeId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tenants/$tenantId/knowledge/$knowledgeId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error deleting knowledge: ${response.body}');
    }
  }

  // Menu Triggers
  Future<List<MenuTrigger>> getMenuTriggers(String tenantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tenants/$tenantId/triggers'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((t) => MenuTrigger.fromJson(t)).toList();
    } else {
      throw Exception('Error fetching triggers: ${response.body}');
    }
  }

  Future<MenuTrigger> createMenuTrigger(MenuTrigger trigger) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tenants/${trigger.tenantId}/triggers'),
      headers: _headers,
      body: jsonEncode(trigger.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return MenuTrigger.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error creating trigger: ${response.body}');
    }
  }

  Future<void> deleteMenuTrigger(String tenantId, String triggerId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tenants/$tenantId/triggers/$triggerId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error deleting trigger: ${response.body}');
    }
  }
}
