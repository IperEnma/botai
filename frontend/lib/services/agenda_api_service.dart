import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/agenda/agenda_notification.dart';
import '../models/agenda/agenda_service.dart';
import '../models/agenda/availability_slot.dart';
import '../models/agenda/booking.dart';
import '../models/agenda/business.dart';
import '../models/agenda/business_hours.dart';
import '../models/agenda/business_photo.dart';
import '../models/agenda/business_settings.dart';
import '../models/agenda/business_summary.dart';
import '../models/agenda/category.dart';
import '../models/agenda/loyalty_suggestion.dart';
import '../models/agenda/notification_template.dart';
import '../models/agenda/plan.dart';
import '../models/agenda/register_tenant.dart';
import '../models/agenda/staff_member.dart';
import '../models/agenda/subscription.dart';
import '../models/agenda/tenant_features.dart';
import '../models/agenda/wallet.dart';
import 'agenda_api_exception.dart';

/// Cliente HTTP único del módulo AGENDA contra `/api/agenda/**`.
///
/// **Aislado del bot:** no comparte estado con `ApiService`. El access token y
/// el `X-User-Id` se setean explícitamente desde el provider correspondiente.
class AgendaApiService {
  AgendaApiService({
    String? baseUrl,
    http.Client? client,
    Duration? timeout,
  })  : baseUrl = baseUrl ?? AppConfig.agendaApiBaseUrl,
        _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 15);

  final String baseUrl;
  final http.Client _client;
  final Duration _timeout;

  String? _accessToken;
  String? _userId;

  void setAccessToken(String? token) => _accessToken = token;
  void setUserId(String? userId) => _userId = userId;

  // ---------------- Headers / IO helpers ----------------

  Map<String, String> _headers({bool sendUserId = false, String? idempotencyKey}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) h['Authorization'] = 'Bearer $_accessToken';
    if (sendUserId && _userId != null) h['X-User-Id'] = _userId!;
    if (idempotencyKey != null) h['Idempotency-Key'] = idempotencyKey;
    return h;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final qs = <String, String>{};
    query?.forEach((k, v) {
      if (v == null) return;
      qs[k] = v is String ? v : v.toString();
    });
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: qs.isEmpty ? null : qs,
    );
  }

  Future<http.Response> _send(Future<http.Response> Function() exec) async {
    try {
      return await exec().timeout(_timeout);
    } on TimeoutException {
      throw const AgendaApiException(
        message: 'La conexión con el servidor tardó demasiado. Reintentá en unos segundos.',
        status: 0,
      );
    } catch (e) {
      throw AgendaApiException(
        message: 'No se pudo contactar al servidor: $e',
        status: 0,
      );
    }
  }

  /// Lanza [AgendaApiException] si la respuesta no es 2xx.
  void _ensureOk(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) { return; }
    String? code;
    String message = 'Error ${r.statusCode}';
    if (r.body.isNotEmpty) {
      try {
        final body = jsonDecode(r.body);
        if (body is Map<String, dynamic>) {
          code = body['code']?.toString();
          final m = body['message']?.toString();
          if (m != null && m.isNotEmpty) { message = m; }
        }
      } catch (_) {/* body no es JSON, ignorar */}
    }
    throw AgendaApiException(message: message, status: r.statusCode, code: code);
  }

  T _decode<T>(http.Response r, T Function(dynamic body) map) {
    _ensureOk(r);
    if (r.body.isEmpty) { return map(null); }
    return map(jsonDecode(r.body));
  }

  List<T> _decodeList<T>(http.Response r, T Function(Map<String, dynamic>) map) {
    return _decode(r, (body) {
      if (body is! List) { return <T>[]; }
      return body
          .whereType<Map>()
          .map((e) => map(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    });
  }

  // =====================================================================
  // PUBLIC — registro
  // =====================================================================

  /// `POST /public/register`
  Future<RegisterTenantResponse> registerTenant({
    required String nombrePropietario,
    required String email,
    String? telefono,
    required String nombreNegocio,
    String? categoriaSlug,
  }) async {
    final body = <String, dynamic>{
      'nombrePropietario': nombrePropietario,
      'email': email,
      'nombreNegocio': nombreNegocio,
      if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
      if (categoriaSlug != null && categoriaSlug.isNotEmpty) 'categoriaSlug': categoriaSlug,
    };
    final r = await _send(() => _client.post(
          _uri('/public/register'),
          headers: _headers(),
          body: jsonEncode(body),
        ));
    return _decode(r, (b) => RegisterTenantResponse.fromJson(b as Map<String, dynamic>));
  }

  // =====================================================================
  // PUBLIC — sin auth
  // =====================================================================

  /// `GET /public/tenants/by-code/{accessCode}`
  Future<String> getTenantByCode(String accessCode) async {
    final r = await _send(() => _client.get(
          _uri('/public/tenants/by-code/$accessCode'),
          headers: _headers(),
        ));
    return _decode(r, (b) => (b as Map<String, dynamic>)['tenantId'] as String);
  }

  /// `GET /public/search?q=...&tenantId=...&categorySlug=...`
  Future<List<BusinessSummary>> search({
    required String q,
    String? tenantId,
    String? categorySlug,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/public/search', {
            'q': q,
            if (tenantId != null && tenantId.isNotEmpty) 'tenantId': tenantId,
            if (categorySlug != null && categorySlug.isNotEmpty)
              'categorySlug': categorySlug,
          }),
          headers: _headers(),
        ));
    return _decodeList(r, BusinessSummary.fromJson);
  }

  /// `GET /public/categories`
  Future<List<Category>> listPublicCategories() async {
    final r = await _send(() => _client.get(
          _uri('/public/categories'),
          headers: _headers(),
        ));
    return _decodeList(r, Category.fromJson);
  }

  /// `GET /public/categories/{slug}/businesses`
  Future<List<BusinessSummary>> businessesByCategory({
    required String slug,
    String? tenantId,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/public/categories/$slug/businesses', {
            if (tenantId != null && tenantId.isNotEmpty) 'tenantId': tenantId,
          }),
          headers: _headers(),
        ));
    return _decodeList(r, BusinessSummary.fromJson);
  }

  /// `GET /public/businesses/{id}`
  Future<Business> publicBusinessDetail(String id) async {
    final r = await _send(() => _client.get(
          _uri('/public/businesses/$id'),
          headers: _headers(),
        ));
    return _decode(r, (body) => Business.fromJson(body as Map<String, dynamic>));
  }

  /// `GET /public/businesses/{id}/staff`
  Future<List<StaffMember>> publicBusinessStaff(String id) async {
    final r = await _send(() => _client.get(
          _uri('/public/businesses/$id/staff'),
          headers: _headers(),
        ));
    return _decodeList(r, StaffMember.fromJson);
  }

  /// `GET /public/businesses/{id}/availability`
  Future<List<AvailabilitySlot>> publicAvailability({
    required String businessId,
    required String serviceId,
    String? staffMemberId,
    required String date,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/public/businesses/$businessId/availability', {
            'serviceId': serviceId,
            'staffMemberId': staffMemberId, // null filtered by _uri()
            'date': date,
          }),
          headers: _headers(),
        ));
    return _decodeList(r, AvailabilitySlot.fromJson);
  }

  /// `GET /public/businesses/{id}/services`
  Future<List<AgendaService>> publicBusinessServices(String id) async {
    final r = await _send(() => _client.get(
          _uri('/public/businesses/$id/services'),
          headers: _headers(),
        ));
    return _decodeList(r, AgendaService.fromJson);
  }

  // =====================================================================
  // PLATFORM — admin del catálogo global
  // =====================================================================

  /// `GET /platform/categories`
  Future<List<Category>> listAllCategories() async {
    final r = await _send(() => _client.get(
          _uri('/platform/categories'),
          headers: _headers(),
        ));
    return _decodeList(r, Category.fromJson);
  }

  /// `POST /platform/categories`
  Future<Category> createCategory({
    required String nombre,
    required String slug,
    required List<String> synonyms,
    bool activo = true,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/platform/categories'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            'slug': slug,
            'synonyms': synonyms,
            'activo': activo,
          }),
        ));
    return _decode(r, (body) => Category.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /platform/categories/{id}`
  Future<Category> updateCategory({
    required String id,
    required String nombre,
    required String slug,
    required List<String> synonyms,
    required bool activo,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/platform/categories/$id'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            'slug': slug,
            'synonyms': synonyms,
            'activo': activo,
          }),
        ));
    return _decode(r, (body) => Category.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /platform/categories/{id}/synonyms` — merge
  Future<Category> mergeCategorySynonyms({
    required String id,
    required List<String> synonyms,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/platform/categories/$id/synonyms'),
          headers: _headers(),
          body: jsonEncode({'synonyms': synonyms}),
        ));
    return _decode(r, (body) => Category.fromJson(body as Map<String, dynamic>));
  }

  /// `DELETE /platform/categories/{id}`
  Future<void> deleteCategory(String id) async {
    final r = await _send(() => _client.delete(
          _uri('/platform/categories/$id'),
          headers: _headers(),
        ));
    _ensureOk(r);
  }

  // =====================================================================
  // TENANT — features
  // =====================================================================

  /// `GET /tenants/{tenantId}/features`
  Future<TenantFeatures> getFeatures(String tenantId) async {
    final r = await _send(() => _client.get(
          _uri('/tenants/$tenantId/features'),
          headers: _headers(),
        ));
    return _decode(
      r,
      (body) => TenantFeatures.fromJson(tenantId, body as Map<String, dynamic>),
    );
  }

  /// `PUT /tenants/{tenantId}/features`
  Future<TenantFeatures> updateFeatures(
    String tenantId,
    TenantFeatures features,
  ) async {
    final r = await _send(() => _client.put(
          _uri('/tenants/$tenantId/features'),
          headers: _headers(),
          body: jsonEncode(features.toRequestJson()),
        ));
    return _decode(
      r,
      (body) => TenantFeatures.fromJson(tenantId, body as Map<String, dynamic>),
    );
  }

  // =====================================================================
  // TENANT — businesses
  // =====================================================================

  /// `GET /tenants/{tenantId}/businesses`
  Future<List<Business>> listBusinesses(String tenantId) async {
    final r = await _send(() => _client.get(
          _uri('/tenants/$tenantId/businesses'),
          headers: _headers(),
        ));
    return _decodeList(r, Business.fromJson);
  }

  /// `POST /tenants/{tenantId}/businesses`
  Future<Business> createBusiness({
    required String tenantId,
    required String nombre,
    String? descripcion,
    List<String> searchTags = const [],
  }) async {
    final r = await _send(() => _client.post(
          _uri('/tenants/$tenantId/businesses'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            'descripcion': ?descripcion,
            'searchTags': searchTags,
          }),
        ));
    return _decode(r, (body) => Business.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /tenants/{tenantId}/businesses/{businessId}`
  Future<Business> updateBusiness({
    required String tenantId,
    required String businessId,
    required String nombre,
    String? descripcion,
    List<String> searchTags = const [],
    String? logoUrl,
    String? colorPrimario,
    String? instagramUrl,
    String? tiktokUrl,
    String? facebookUrl,
    String? colorFondo,
    String? fontFamily,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/tenants/$tenantId/businesses/$businessId'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            'descripcion': ?descripcion,
            'searchTags': searchTags,
            'logoUrl': logoUrl,
            'colorPrimario': colorPrimario,
            'instagramUrl': instagramUrl,
            'tiktokUrl': tiktokUrl,
            'facebookUrl': facebookUrl,
            'colorFondo': colorFondo,
            'fontFamily': fontFamily,
          }),
        ));
    return _decode(r, (body) => Business.fromJson(body as Map<String, dynamic>));
  }

  /// `POST /tenants/{tenantId}/businesses/{businessId}/avatar`
  Future<String> uploadBusinessAvatar({
    required String tenantId,
    required String businessId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('$baseUrl/tenants/$tenantId/businesses/$businessId/avatar');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json';
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final streamed = await request.send().timeout(_timeout);
    final r = await http.Response.fromStream(streamed);
    return _decode(r, (body) => (body as Map<String, dynamic>)['url'] as String);
  }

  /// `POST /tenants/{tenantId}/businesses/{businessId}/staff/{staffId}/avatar`
  Future<String> uploadStaffAvatar({
    required String tenantId,
    required String businessId,
    required String staffId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse(
        '$baseUrl/tenants/$tenantId/businesses/$businessId/staff/$staffId/avatar');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json';
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final streamed = await request.send().timeout(_timeout);
    final r = await http.Response.fromStream(streamed);
    return _decode(r, (body) => (body as Map<String, dynamic>)['url'] as String);
  }

  // =====================================================================
  // TENANT — business hours
  // =====================================================================

  /// `GET /tenants/{tenantId}/businesses/{businessId}/hours`
  Future<List<BusinessHours>> getBusinessHours({
    required String tenantId,
    required String businessId,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/tenants/$tenantId/businesses/$businessId/hours'),
          headers: _headers(),
        ));
    return _decodeList(r, BusinessHours.fromJson);
  }

  /// `PUT /tenants/{tenantId}/businesses/{businessId}/hours`
  Future<List<BusinessHours>> saveBusinessHours({
    required String tenantId,
    required String businessId,
    required List<BusinessHours> hours,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/tenants/$tenantId/businesses/$businessId/hours'),
          headers: _headers(),
          body: jsonEncode({'horarios': hours.map((h) => h.toJson()).toList()}),
        ));
    return _decodeList(r, BusinessHours.fromJson);
  }

  /// `PUT /tenants/{tenantId}/businesses/{businessId}/categories`
  Future<void> associateCategories({
    required String tenantId,
    required String businessId,
    required List<String> categoryIds,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/tenants/$tenantId/businesses/$businessId/categories'),
          headers: _headers(),
          body: jsonEncode({'categoryIds': categoryIds}),
        ));
    _ensureOk(r);
  }

  /// `GET /tenants/{tenantId}/businesses/{businessId}/photos`
  Future<List<BusinessPhoto>> getBusinessPhotos({
    required String tenantId,
    required String businessId,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/tenants/$tenantId/businesses/$businessId/photos'),
          headers: _headers(),
        ));
    return _decodeList(r, BusinessPhoto.fromJson);
  }

  /// `POST /tenants/{tenantId}/businesses/{businessId}/photos`
  Future<BusinessPhoto> addBusinessPhoto({
    required String tenantId,
    required String businessId,
    required String url,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/tenants/$tenantId/businesses/$businessId/photos'),
          headers: _headers(),
          body: jsonEncode({'url': url}),
        ));
    return _decode(r, (body) => BusinessPhoto.fromJson(body as Map<String, dynamic>));
  }

  /// `DELETE /tenants/{tenantId}/businesses/{businessId}/photos/{photoId}`
  Future<void> deleteBusinessPhoto({
    required String tenantId,
    required String businessId,
    required String photoId,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/tenants/$tenantId/businesses/$businessId/photos/$photoId'),
          headers: _headers(),
        ));
    _ensureOk(r);
  }

  /// `GET /tenants/{tenantId}/businesses/{businessId}/settings`
  Future<BusinessSettings> getSettings({
    required String tenantId,
    required String businessId,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/tenants/$tenantId/businesses/$businessId/settings'),
          headers: _headers(),
        ));
    return _decode(
      r,
      (body) => BusinessSettings.fromJson(body as Map<String, dynamic>),
    );
  }

  /// `PUT /tenants/{tenantId}/businesses/{businessId}/settings`
  Future<BusinessSettings> updateSettings({
    required String tenantId,
    required String businessId,
    required BusinessSettings settings,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/tenants/$tenantId/businesses/$businessId/settings'),
          headers: _headers(),
          body: jsonEncode(settings.toRequestJson()),
        ));
    return _decode(
      r,
      (body) => BusinessSettings.fromJson(body as Map<String, dynamic>),
    );
  }

  // =====================================================================
  // TENANT — services
  // =====================================================================

  /// `GET /tenants/{tenantId}/businesses/{businessId}/services`
  Future<List<AgendaService>> listTenantServices({
    required String tenantId,
    required String businessId,
    bool soloActivos = false,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/tenants/$tenantId/businesses/$businessId/services', {
            if (soloActivos) 'soloActivos': 'true',
          }),
          headers: _headers(),
        ));
    return _decodeList(r, AgendaService.fromJson);
  }

  /// `POST /tenants/{tenantId}/businesses/{businessId}/services`
  Future<AgendaService> createService({
    required String tenantId,
    required String businessId,
    required String nombre,
    String? descripcion,
    required int duracionMin,
    required double precio,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/tenants/$tenantId/businesses/$businessId/services'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            'descripcion': ?descripcion,
            'duracionMin': duracionMin,
            'precio': precio,
          }),
        ));
    return _decode(r, (body) => AgendaService.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /tenants/{tenantId}/businesses/{businessId}/services/{serviceId}`
  Future<AgendaService> updateService({
    required String tenantId,
    required String businessId,
    required String serviceId,
    required String nombre,
    String? descripcion,
    required int duracionMin,
    required double precio,
    required bool activo,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/tenants/$tenantId/businesses/$businessId/services/$serviceId'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            'descripcion': ?descripcion,
            'duracionMin': duracionMin,
            'precio': precio,
            'activo': activo,
          }),
        ));
    return _decode(r, (body) => AgendaService.fromJson(body as Map<String, dynamic>));
  }

  /// `DELETE /tenants/{tenantId}/businesses/{businessId}/services/{serviceId}`
  Future<void> deleteService({
    required String tenantId,
    required String businessId,
    required String serviceId,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/tenants/$tenantId/businesses/$businessId/services/$serviceId'),
          headers: _headers(),
        ));
    _ensureOk(r);
  }

  // =====================================================================
  // TENANT — plans
  // =====================================================================

  /// `GET /tenants/{tenantId}/businesses/{businessId}/plans`
  Future<List<Plan>> listPlans({
    required String tenantId,
    required String businessId,
    bool onlyActive = false,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/tenants/$tenantId/businesses/$businessId/plans', {
            if (onlyActive) 'onlyActive': 'true',
          }),
          headers: _headers(),
        ));
    return _decodeList(r, Plan.fromJson);
  }

  /// `POST /tenants/{tenantId}/businesses/{businessId}/plans`
  Future<Plan> createPlan({
    required String tenantId,
    required String businessId,
    required String nombrePlan,
    required PlanTipo tipo,
    PlanTier? tier,
    required int totalCreditos,
    required int validezDias,
    required double precio,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/tenants/$tenantId/businesses/$businessId/plans'),
          headers: _headers(),
          body: jsonEncode({
            'nombrePlan': nombrePlan,
            'tipo': tipo.toBackendString(),
            if (tier != null) 'tier': tier.toBackendString(),
            'totalCreditos': totalCreditos,
            'validezDias': validezDias,
            'precio': precio,
          }),
        ));
    return _decode(r, (body) => Plan.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /tenants/{tenantId}/businesses/{businessId}/plans/{planId}`
  Future<Plan> updatePlan({
    required String tenantId,
    required String businessId,
    required String planId,
    required String nombrePlan,
    required PlanTipo tipo,
    PlanTier? tier,
    required int totalCreditos,
    required int validezDias,
    required double precio,
    required bool activo,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/tenants/$tenantId/businesses/$businessId/plans/$planId'),
          headers: _headers(),
          body: jsonEncode({
            'nombrePlan': nombrePlan,
            'tipo': tipo.toBackendString(),
            if (tier != null) 'tier': tier.toBackendString(),
            'totalCreditos': totalCreditos,
            'validezDias': validezDias,
            'precio': precio,
            'activo': activo,
          }),
        ));
    return _decode(r, (body) => Plan.fromJson(body as Map<String, dynamic>));
  }

  /// `DELETE /tenants/{tenantId}/businesses/{businessId}/plans/{planId}`
  Future<void> deletePlan({
    required String tenantId,
    required String businessId,
    required String planId,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/tenants/$tenantId/businesses/$businessId/plans/$planId'),
          headers: _headers(),
        ));
    _ensureOk(r);
  }

  // =====================================================================
  // TENANT — loyalty suggestions
  // =====================================================================

  /// `GET /tenants/{tenantId}/businesses/{businessId}/loyalty/suggestions`
  Future<List<LoyaltySuggestion>> listLoyaltySuggestions({
    required String tenantId,
    required String businessId,
    LoyaltySuggestionEstado? estado,
  }) async {
    final r = await _send(() => _client.get(
          _uri(
            '/tenants/$tenantId/businesses/$businessId/loyalty/suggestions',
            {if (estado != null) 'estado': estado.toBackendString()},
          ),
          headers: _headers(),
        ));
    return _decodeList(r, LoyaltySuggestion.fromJson);
  }

  /// `PATCH /tenants/{tenantId}/businesses/{businessId}/loyalty/suggestions/{id}`
  Future<LoyaltySuggestion> patchLoyaltySuggestion({
    required String tenantId,
    required String businessId,
    required String id,
    required LoyaltySuggestionEstado estado,
  }) async {
    final r = await _send(() => _client.patch(
          _uri('/tenants/$tenantId/businesses/$businessId/loyalty/suggestions/$id'),
          headers: _headers(),
          body: jsonEncode({'estado': estado.toBackendString()}),
        ));
    return _decode(r, (body) => LoyaltySuggestion.fromJson(body as Map<String, dynamic>));
  }

  /// `POST /tenants/{tenantId}/businesses/{businessId}/loyalty/suggestions/{id}/send`
  Future<LoyaltySuggestion> sendLoyaltySuggestion({
    required String tenantId,
    required String businessId,
    required String id,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/tenants/$tenantId/businesses/$businessId/loyalty/suggestions/$id/send'),
          headers: _headers(),
        ));
    return _decode(r, (body) => LoyaltySuggestion.fromJson(body as Map<String, dynamic>));
  }

  // =====================================================================
  // TENANT — notification templates
  // =====================================================================

  /// `GET /tenants/{tenantId}/businesses/{businessId}/templates`
  Future<List<NotificationTemplate>> listTemplates({
    required String tenantId,
    required String businessId,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/tenants/$tenantId/businesses/$businessId/templates'),
          headers: _headers(),
        ));
    return _decodeList(r, NotificationTemplate.fromJson);
  }

  /// `POST /tenants/{tenantId}/businesses/{businessId}/templates`
  Future<NotificationTemplate> createTemplate({
    required String tenantId,
    required String businessId,
    required String codigo,
    required NotificationCanal canal,
    required String titulo,
    required String cuerpo,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/tenants/$tenantId/businesses/$businessId/templates'),
          headers: _headers(),
          body: jsonEncode({
            'codigo': codigo,
            'canal': canal.toBackendString(),
            'titulo': titulo,
            'cuerpo': cuerpo,
          }),
        ));
    return _decode(r, (body) => NotificationTemplate.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /tenants/{tenantId}/businesses/{businessId}/templates/{id}`
  Future<NotificationTemplate> updateTemplate({
    required String tenantId,
    required String businessId,
    required String id,
    required String titulo,
    required String cuerpo,
    required NotificationCanal canal,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/tenants/$tenantId/businesses/$businessId/templates/$id'),
          headers: _headers(),
          body: jsonEncode({
            'titulo': titulo,
            'cuerpo': cuerpo,
            'canal': canal.toBackendString(),
          }),
        ));
    return _decode(r, (body) => NotificationTemplate.fromJson(body as Map<String, dynamic>));
  }

  /// `DELETE /tenants/{tenantId}/businesses/{businessId}/templates/{id}`
  Future<void> deleteTemplate({
    required String tenantId,
    required String businessId,
    required String id,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/tenants/$tenantId/businesses/$businessId/templates/$id'),
          headers: _headers(),
        ));
    _ensureOk(r);
  }

  // =====================================================================
  // ME — subscriptions
  // =====================================================================

  /// `POST /tenants/{tenantId}/businesses/{businessId}/plans/{planId}/subscribe`
  Future<Subscription> purchaseSubscription({
    required String tenantId,
    required String businessId,
    required String planId,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/tenants/$tenantId/businesses/$businessId/plans/$planId/subscribe'),
          headers: _headers(sendUserId: true),
        ));
    return _decode(r, (body) => Subscription.fromJson(body as Map<String, dynamic>));
  }

  /// `GET /me/subscriptions`
  Future<List<Subscription>> mySubscriptions({bool onlyActive = false}) async {
    final r = await _send(() => _client.get(
          _uri('/me/subscriptions', {
            if (onlyActive) 'onlyActive': 'true',
          }),
          headers: _headers(sendUserId: true),
        ));
    return _decodeList(r, Subscription.fromJson);
  }

  /// `GET /me/subscriptions/{subscriptionId}/wallet`
  Future<Wallet> myWallet(String subscriptionId) async {
    final r = await _send(() => _client.get(
          _uri('/me/subscriptions/$subscriptionId/wallet'),
          headers: _headers(sendUserId: true),
        ));
    return _decode(r, (body) => Wallet.fromJson(body as Map<String, dynamic>));
  }

  // =====================================================================
  // ME — bookings
  // =====================================================================

  /// `POST /tenants/{tenantId}/businesses/{businessId}/bookings`
  Future<Booking> createBooking({
    required String tenantId,
    required String businessId,
    required String serviceId,
    required DateTime fechaHoraInicio,
    BookingTipo tipoReserva = BookingTipo.pagoPorTurno,
    String? subscriptionId,
    String? notas,
    String? idempotencyKey,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/tenants/$tenantId/businesses/$businessId/bookings'),
          headers: _headers(sendUserId: true, idempotencyKey: idempotencyKey),
          body: jsonEncode({
            'serviceId': serviceId,
            'fechaHoraInicio': fechaHoraInicio.toIso8601String(),
            'tipoReserva': tipoReserva.toBackendString(),
            'subscriptionId': ?subscriptionId,
            if (notas != null && notas.isNotEmpty) 'notas': notas,
          }),
        ));
    return _decode(r, (body) => Booking.fromJson(body as Map<String, dynamic>));
  }

  /// `GET /me/bookings`
  Future<List<Booking>> myBookings({
    String? tenantId,
    String? businessId,
    BookingEstado? estado,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/me/bookings', {
            'tenantId': ?tenantId,
            'businessId': ?businessId,
            if (estado != null) 'estado': estado.name.toUpperCase(),
          }),
          headers: _headers(sendUserId: true),
        ));
    return _decodeList(r, Booking.fromJson);
  }

  /// `DELETE /tenants/{tenantId}/businesses/{businessId}/bookings/{bookingId}`
  Future<void> cancelBooking({
    required String tenantId,
    required String businessId,
    required String bookingId,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/tenants/$tenantId/businesses/$businessId/bookings/$bookingId'),
          headers: _headers(sendUserId: true),
        ));
    _ensureOk(r);
  }

  // =====================================================================
  // ME — notifications
  // =====================================================================

  /// `GET /me/notifications`
  Future<List<AgendaNotification>> myNotifications({
    NotificationEstado? estado,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/me/notifications', {
            if (estado != null) 'estado': estado.name.toUpperCase(),
          }),
          headers: _headers(sendUserId: true),
        ));
    return _decodeList(r, AgendaNotification.fromJson);
  }

  // =====================================================================
  // TENANT — staff members
  // =====================================================================

  /// `GET /tenants/{tenantId}/businesses/{businessId}/staff`
  Future<List<StaffMember>> getStaffMembers({
    required String tenantId,
    required String businessId,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/tenants/$tenantId/businesses/$businessId/staff'),
          headers: _headers(),
        ));
    return _decodeList(r, StaffMember.fromJson);
  }

  /// `POST /tenants/{tenantId}/businesses/{businessId}/staff`
  Future<StaffMember> createStaffMember({
    required String tenantId,
    required String businessId,
    required String nombre,
    String? rol,
    String? avatarUrl,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/tenants/$tenantId/businesses/$businessId/staff'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            if (rol != null && rol.isNotEmpty) 'rol': rol,
            if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
          }),
        ));
    return _decode(r, (body) => StaffMember.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /tenants/{tenantId}/businesses/{businessId}/staff/{staffId}`
  Future<StaffMember> updateStaffMember({
    required String tenantId,
    required String businessId,
    required String staffId,
    required String nombre,
    String? rol,
    String? avatarUrl,
    required bool activo,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/tenants/$tenantId/businesses/$businessId/staff/$staffId'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            if (rol != null && rol.isNotEmpty) 'rol': rol,
            if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
            'activo': activo,
          }),
        ));
    return _decode(r, (body) => StaffMember.fromJson(body as Map<String, dynamic>));
  }

  /// `DELETE /tenants/{tenantId}/businesses/{businessId}/staff/{staffId}` → 204
  Future<void> deleteStaffMember({
    required String tenantId,
    required String businessId,
    required String staffId,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/tenants/$tenantId/businesses/$businessId/staff/$staffId'),
          headers: _headers(),
        ));
    _ensureOk(r);
  }

  /// Cierra el http client subyacente (testing).
  void close() => _client.close();
}
