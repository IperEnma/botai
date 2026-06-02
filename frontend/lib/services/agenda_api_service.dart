import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_error_presenter.dart';
import '../core/auth_bearer_token.dart';
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
import '../models/agenda/category.dart' as agenda;
import '../models/agenda/loyalty_suggestion.dart';
import '../models/agenda/notification_template.dart';
import '../models/agenda/plan.dart';
import '../models/agenda/public_client.dart';
import '../models/agenda/public_company.dart';
import '../models/agenda/register_tenant.dart';
import '../models/agenda/tenant_admin_context.dart';
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
  Future<String?> Function()? _refreshAccessToken;

  void setAccessToken(String? token) =>
      _accessToken = normalizeGoogleBearer(token);
  void setUserId(String? userId) => _userId = userId;
  String? get userId => _userId;
  void setRefreshAccessTokenCallback(Future<String?> Function()? cb) =>
      _refreshAccessToken = cb;

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

  /// Headers para `/api/agenda/public/**` — sin JWT para no provocar 401 con token vencido.
  Map<String, String> _publicHeaders({String? idempotencyKey}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
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
      final first = await exec().timeout(_timeout);
      if (first.statusCode == 401 && _refreshAccessToken != null) {
        final newToken = await _refreshAccessToken!();
        if (newToken != null && newToken.trim().isNotEmpty) {
          setAccessToken(newToken);
          return await exec().timeout(_timeout);
        }
      }
      return first;
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

  /// Igual que [_send] pero sin reintento por 401 ni cabecera Authorization.
  Future<http.Response> _sendPublic(Future<http.Response> Function() exec) async {
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
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return;
    }
    String? code;
    String? detail;
    var message = 'Error ${r.statusCode}';
    if (r.body.isNotEmpty) {
      try {
        final body = jsonDecode(r.body);
        if (body is Map<String, dynamic>) {
          code = body['code']?.toString();
          final m = body['message']?.toString();
          if (m != null && m.isNotEmpty) message = m;
          // Expose field-level validation errors
          final details = body['details'];
          if (details is List && details.isNotEmpty) {
            detail = details
                .whereType<Map>()
                .map((e) => '${e['field']}: ${e['message']}')
                .join(', ');
          }
        }
      } catch (_) {/* body no es JSON */}
    }
    throw AgendaApiException(message: message, status: r.statusCode, code: code, detail: detail);
  }

  /// Respuesta enriquecida (OAuth2 / `WWW-Authenticate`) solo para el probe JWT tras iniciar sesión.
  Never _throwTenantAdminProbeFailure(http.Response r) {
    final diagnostic = parseHttpErrorBody(
      r.statusCode,
      r.body,
      headers: r.headers,
    );
    String? code;
    var message = diagnostic;
    if (r.body.isNotEmpty) {
      try {
        final body = jsonDecode(r.body);
        if (body is Map<String, dynamic>) {
          code = body['code']?.toString();
          final m = body['message']?.toString();
          final err = body['error']?.toString();
          final desc = body['error_description']?.toString();
          if (m != null && m.isNotEmpty) {
            message = m;
          } else if (err != null && err.isNotEmpty) {
            message =
                desc != null && desc.isNotEmpty ? '$err: $desc' : err;
          }
        }
      } catch (_) {/* seguir con diagnostic */}
    }
    final detail = (diagnostic != message) ? diagnostic : null;
    throw AgendaApiException(
      message: message,
      status: r.statusCode,
      code: code,
      detail: detail,
    );
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

  /// `POST /public/register` — indicar exactamente uno: [email] o [numero] (solo dígitos, WhatsApp).
  Future<RegisterTenantResponse> registerTenant({
    required String nombrePropietario,
    String? email,
    String? numero,
    String? telefono,
    required String nombreNegocio,
    String? categoriaSlug,
  }) async {
    final trimmedEmail = email?.trim() ?? '';
    final digitsNumero = numero?.replaceAll(RegExp(r'\D'), '') ?? '';
    final hasEmail = trimmedEmail.isNotEmpty;
    final hasNumero = digitsNumero.isNotEmpty;
    if (hasEmail == hasNumero) {
      throw ArgumentError('Indicá email o numero (teléfono con dígitos), uno solo.');
    }
    final body = <String, dynamic>{
      'nombrePropietario': nombrePropietario,
      'nombreNegocio': nombreNegocio,
      if (hasEmail) 'email': trimmedEmail.toLowerCase(),
      if (hasNumero) 'numero': digitsNumero,
      if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
      if (categoriaSlug != null && categoriaSlug.isNotEmpty) 'categoriaSlug': categoriaSlug,
    };
    final r = await _sendPublic(() => _client.post(
          _uri('/public/register'),
          headers: _publicHeaders(),
          body: jsonEncode(body),
        ));
    return _decode(r, (b) => RegisterTenantResponse.fromJson(b as Map<String, dynamic>));
  }

  /// `GET /me/tenant-admin` — tenant del administrador según email de cuenta.
  Future<TenantAdminContext> fetchTenantAdminContext() async {
    final r = await _send(() => _client.get(
          _uri('/me/tenant-admin'),
          headers: _headers(),
        ));
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return TenantAdminContext.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>,
      );
    }
    _throwTenantAdminProbeFailure(r);
  }

  /// `POST /me/tenant-admin/link` — asocia la sesión Google a la cuenta Agenda identificada por teléfono
  Future<TenantAdminContext> linkTenantAdminWithAccessCode(String accessCode) async {
    final r = await _send(() => _client.post(
          _uri('/me/tenant-admin/link'),
          headers: _headers(),
          body: jsonEncode({'accessCode': accessCode.trim()}),
        ));
    return _decode(
      r,
      (b) => TenantAdminContext.fromJson(b as Map<String, dynamic>),
    );
  }

  /// `POST /me/tenant-admin/identifiers` — agrega email o numero a la cuenta actual.
  Future<TenantAdminContext> linkTenantIdentifier({
    String? email,
    String? numero,
  }) async {
    final trimmedEmail = email?.trim() ?? '';
    final digitsNumero = numero?.replaceAll(RegExp(r'\D'), '') ?? '';
    final hasEmail = trimmedEmail.isNotEmpty;
    final hasNumero = digitsNumero.isNotEmpty;
    if (hasEmail == hasNumero) {
      throw ArgumentError('Indicá email o numero (teléfono con dígitos), uno solo.');
    }
    final r = await _send(() => _client.post(
          _uri('/me/tenant-admin/identifiers'),
          headers: _headers(),
          body: jsonEncode({
            if (hasEmail) 'email': trimmedEmail.toLowerCase(),
            if (hasNumero) 'numero': digitsNumero,
          }),
        ));
    return _decode(
      r,
      (b) => TenantAdminContext.fromJson(b as Map<String, dynamic>),
    );
  }

  /// `GET /me/public-link` — link público amigable (persistido) para este tenant.
  Future<Map<String, String>> mePublicLink() async {
    final r = await _send(() => _client.get(
          _uri('/me/public-link'),
          headers: _headers(),
        ));
    return _decode(r, (b) {
      final m = b as Map<String, dynamic>;
      return {
        'slug': (m['slug'] ?? '').toString(),
        'url': (m['url'] ?? '').toString(),
        'businessId': (m['businessId'] ?? '').toString(),
        'companySlug': (m['companySlug'] ?? '').toString(),
      };
    });
  }

  /// `GET /public/companies/{companySlug}` — marca y sucursales (Felito-style).
  Future<PublicCompany> publicCompanyDetail(String companySlug) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/companies/$companySlug'),
          headers: _publicHeaders(),
        ));
    return _decode(r, (b) => PublicCompany.fromJson(b as Map<String, dynamic>));
  }

  /// `GET /public/links/{slug}` — resuelve slug → businessId.
  Future<String> resolvePublicSlug(String slug) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/links/$slug'),
          headers: _publicHeaders(),
        ));
    return _decode(r, (b) => (b as Map<String, dynamic>)['businessId'] as String);
  }

  /// `GET /public/businesses/by-slug/{slug}`
  Future<Business> publicBusinessDetailBySlug(String slug) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/businesses/by-slug/$slug'),
          headers: _publicHeaders(),
        ));
    return _decode(r, (body) => Business.fromJson(body as Map<String, dynamic>));
  }

  /// `GET /public/businesses/by-slug/{slug}/services`
  Future<List<AgendaService>> publicBusinessServicesBySlug(String slug) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/businesses/by-slug/$slug/services'),
          headers: _publicHeaders(),
        ));
    return _decodeList(r, AgendaService.fromJson);
  }

  /// `GET /public/businesses/by-slug/{slug}/staff`
  Future<List<StaffMember>> publicBusinessStaffBySlug(String slug) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/businesses/by-slug/$slug/staff'),
          headers: _publicHeaders(),
        ));
    return _decodeList(r, StaffMember.fromJson);
  }

  /// `GET /public/businesses/by-slug/{slug}/availability`
  Future<List<AvailabilitySlot>> publicAvailabilityBySlug({
    required String slug,
    required String serviceId,
    String? staffMemberId,
    required String date,
  }) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/businesses/by-slug/$slug/availability', {
            'serviceId': serviceId,
            'staffMemberId': staffMemberId,
            'date': date,
          }),
          headers: _publicHeaders(),
        ));
    return _decodeList(r, AvailabilitySlot.fromJson);
  }

  /// `GET /public/businesses/by-slug/{slug}/hours`
  Future<List<BusinessHours>> publicBusinessHoursBySlug(String slug) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/businesses/by-slug/$slug/hours'),
          headers: _publicHeaders(),
        ));
    return _decodeList(r, BusinessHours.fromJson);
  }

  // =====================================================================
  // PUBLIC — sin auth
  // =====================================================================

  /// `GET /public/tenants/by-code/{accessCode}`
  Future<String> getTenantByCode(String accessCode) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/tenants/by-code/$accessCode'),
          headers: _publicHeaders(),
        ));
    return _decode(r, (b) => (b as Map<String, dynamic>)['tenantId'] as String);
  }

  /// `GET /public/search?q=...&tenantId=...&categorySlug=...`
  Future<List<BusinessSummary>> search({
    required String q,
    String? tenantId,
    String? categorySlug,
  }) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/search', {
            'q': q,
            if (tenantId != null && tenantId.isNotEmpty) 'tenantId': tenantId,
            if (categorySlug != null && categorySlug.isNotEmpty)
              'categorySlug': categorySlug,
          }),
          headers: _publicHeaders(),
        ));
    return _decodeList(r, BusinessSummary.fromJson);
  }

  /// `GET /public/categories`
  Future<List<agenda.Category>> listPublicCategories() async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/categories'),
          headers: _publicHeaders(),
        ));
    return _decodeList(r, agenda.Category.fromJson);
  }

  /// `GET /public/categories/{slug}/businesses`
  Future<List<BusinessSummary>> businessesByCategory({
    required String slug,
    String? tenantId,
  }) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/categories/$slug/businesses', {
            if (tenantId != null && tenantId.isNotEmpty) 'tenantId': tenantId,
          }),
          headers: _publicHeaders(),
        ));
    return _decodeList(r, BusinessSummary.fromJson);
  }

  /// `GET /public/businesses/{id}`
  Future<Business> publicBusinessDetail(String id) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/businesses/$id'),
          headers: _publicHeaders(),
        ));
    return _decode(r, (body) => Business.fromJson(body as Map<String, dynamic>));
  }

  /// `GET /public/businesses/{id}/staff`
  Future<List<StaffMember>> publicBusinessStaff(String id) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/businesses/$id/staff'),
          headers: _publicHeaders(),
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
    final r = await _sendPublic(() => _client.get(
          _uri('/public/businesses/$businessId/availability', {
            'serviceId': serviceId,
            'staffMemberId': staffMemberId, // null filtered by _uri()
            'date': date,
          }),
          headers: _publicHeaders(),
        ));
    return _decodeList(r, AvailabilitySlot.fromJson);
  }

  /// `GET /public/businesses/{id}/hours`
  Future<List<BusinessHours>> publicBusinessHours(String businessId) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/businesses/$businessId/hours'),
          headers: _publicHeaders(),
        ));
    return _decodeList(r, BusinessHours.fromJson);
  }

  /// `GET /public/businesses/{id}/services`
  Future<List<AgendaService>> publicBusinessServices(String id) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/businesses/$id/services'),
          headers: _publicHeaders(),
        ));
    return _decodeList(r, AgendaService.fromJson);
  }

  /// `GET /public/businesses/{businessId}/clients?q=`
  Future<List<PublicClient>> searchClients({
    required String businessId,
    required String q,
  }) async {
    final r = await _sendPublic(() => _client.get(
          _uri('/public/businesses/$businessId/clients', {'q': q}),
          headers: _publicHeaders(),
        ));
    return _decodeList(r, PublicClient.fromJson);
  }

  /// `POST /public/businesses/{businessId}/clients`
  Future<PublicClient> createClient({
    required String businessId,
    required String nombre,
    required String telefono,
    String? email,
  }) async {
    final r = await _sendPublic(() => _client.post(
          _uri('/public/businesses/$businessId/clients'),
          headers: _publicHeaders(),
          body: jsonEncode({
            'nombre': nombre,
            'telefono': telefono,
            if (email != null && email.isNotEmpty) 'email': email,
          }),
        ));
    return _decode(r, (body) => PublicClient.fromJson(body as Map<String, dynamic>));
  }

  /// `POST /public/businesses/{businessId}/bookings`
  ///
  /// Crea una reserva en estado PENDING (flujo público, sin auth).
  Future<Booking> publicCreateBooking({
    required String businessId,
    required String serviceId,
    String? staffMemberId,
    required DateTime fechaHoraInicio,
    required String clientId,
    String? notas,
  }) async {
    final r = await _sendPublic(() => _client.post(
          _uri('/public/businesses/$businessId/bookings'),
          headers: _publicHeaders(),
          body: jsonEncode({
            'serviceId': serviceId,
            if (staffMemberId != null) 'staffMemberId': staffMemberId,
            'fechaHoraInicio': _fmtLocalDateTime(fechaHoraInicio),
            'clientId': clientId,
            if (notas != null && notas.isNotEmpty) 'notas': notas,
          }),
        ));
    return _decode(r, (body) => Booking.fromJson(body as Map<String, dynamic>));
  }

  // =====================================================================
  // PLATFORM — admin del catálogo global
  // =====================================================================

  /// `GET /platform/categories`
  Future<List<agenda.Category>> listAllCategories() async {
    final r = await _send(() => _client.get(
          _uri('/platform/categories'),
          headers: _headers(),
        ));
    return _decodeList(r, agenda.Category.fromJson);
  }

  /// `POST /platform/categories`
  Future<agenda.Category> createCategory({
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
    return _decode(r, (body) => agenda.Category.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /platform/categories/{id}`
  Future<agenda.Category> updateCategory({
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
    return _decode(r, (body) => agenda.Category.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /platform/categories/{id}/synonyms` — merge
  Future<agenda.Category> mergeCategorySynonyms({
    required String id,
    required List<String> synonyms,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/platform/categories/$id/synonyms'),
          headers: _headers(),
          body: jsonEncode({'synonyms': synonyms}),
        ));
    return _decode(r, (body) => agenda.Category.fromJson(body as Map<String, dynamic>));
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
  // ME — features
  // =====================================================================

  /// `GET /me/features`
  Future<TenantFeatures> getFeatures() async {
    final r = await _send(() => _client.get(
          _uri('/me/features'),
          headers: _headers(),
        ));
    return _decode(
      r,
      (body) => TenantFeatures.fromJson('me', body as Map<String, dynamic>),
    );
  }

  /// `PUT /me/features`
  Future<TenantFeatures> updateFeatures(TenantFeatures features) async {
    final r = await _send(() => _client.put(
          _uri('/me/features'),
          headers: _headers(),
          body: jsonEncode(features.toRequestJson()),
        ));
    return _decode(
      r,
      (body) => TenantFeatures.fromJson('me', body as Map<String, dynamic>),
    );
  }

  // =====================================================================
  // TENANT — businesses
  // =====================================================================

  /// `GET /tenants/{tenantId}/businesses`
  Future<List<Business>> listBusinesses(String tenantId) async {
    final r = await _send(() => _client.get(
          _uri('/me/businesses'),
          headers: _headers(),
        ));
    return _decodeList(r, Business.fromJson);
  }

  /// `POST /me/businesses`
  Future<Business> createBusiness({
    required String nombre,
    String? descripcion,
    List<String> searchTags = const [],
    String? ownerUserId,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/me/businesses'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            if (descripcion != null) 'descripcion': descripcion,
            'searchTags': searchTags,
            if (ownerUserId != null && ownerUserId.isNotEmpty)
              'ownerUserId': ownerUserId,
          }),
        ));
    return _decode(r, (body) => Business.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /me/businesses/{businessId}`
  Future<Business> updateBusiness({
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
          _uri('/me/businesses/$businessId'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            if (descripcion != null) 'descripcion': descripcion,
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

  /// `POST /me/businesses/{businessId}/avatar`
  Future<String> uploadBusinessAvatar({
    required String businessId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('$baseUrl/me/businesses/$businessId/avatar');
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

  /// `POST /me/businesses/{businessId}/staff/{staffId}/avatar`
  Future<String> uploadStaffAvatar({
    required String businessId,
    required String staffId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse(
        '$baseUrl/me/businesses/$businessId/staff/$staffId/avatar');
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

  /// `GET /me/businesses/{businessId}/hours`
  Future<List<BusinessHours>> getBusinessHours({
    required String businessId,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/me/businesses/$businessId/hours'),
          headers: _headers(),
        ));
    return _decodeList(r, BusinessHours.fromJson);
  }

  /// `PUT /me/businesses/{businessId}/hours`
  Future<List<BusinessHours>> saveBusinessHours({
    required String businessId,
    required List<BusinessHours> hours,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/me/businesses/$businessId/hours'),
          headers: _headers(),
          body: jsonEncode({'horarios': hours.map((h) => h.toJson()).toList()}),
        ));
    return _decodeList(r, BusinessHours.fromJson);
  }

  /// `PUT /me/businesses/{businessId}/categories`
  Future<void> associateCategories({
    required String businessId,
    required List<String> categoryIds,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/me/businesses/$businessId/categories'),
          headers: _headers(),
          body: jsonEncode({'categoryIds': categoryIds}),
        ));
    _ensureOk(r);
  }

  /// `GET /me/businesses/{businessId}/photos`
  Future<List<BusinessPhoto>> getBusinessPhotos({
    required String businessId,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/me/businesses/$businessId/photos'),
          headers: _headers(),
        ));
    return _decodeList(r, BusinessPhoto.fromJson);
  }

  /// `POST /me/businesses/{businessId}/photos`
  Future<BusinessPhoto> addBusinessPhoto({
    required String businessId,
    required String url,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/me/businesses/$businessId/photos'),
          headers: _headers(),
          body: jsonEncode({'url': url}),
        ));
    return _decode(r, (body) => BusinessPhoto.fromJson(body as Map<String, dynamic>));
  }

  /// `DELETE /me/businesses/{businessId}/photos/{photoId}`
  Future<void> deleteBusinessPhoto({
    required String businessId,
    required String photoId,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/me/businesses/$businessId/photos/$photoId'),
          headers: _headers(),
        ));
    _ensureOk(r);
  }

  /// `GET /me/businesses/{businessId}/settings`
  Future<BusinessSettings> getSettings({
    required String businessId,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/me/businesses/$businessId/settings'),
          headers: _headers(),
        ));
    return _decode(
      r,
      (body) => BusinessSettings.fromJson(body as Map<String, dynamic>),
    );
  }

  /// `PUT /me/businesses/{businessId}/settings`
  Future<BusinessSettings> updateSettings({
    required String businessId,
    required BusinessSettings settings,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/me/businesses/$businessId/settings'),
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

  /// `GET /me/businesses/{businessId}/services`
  Future<List<AgendaService>> listTenantServices({
    required String businessId,
    bool soloActivos = false,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/me/businesses/$businessId/services', {
            if (soloActivos) 'soloActivos': 'true',
          }),
          headers: _headers(),
        ));
    return _decodeList(r, AgendaService.fromJson);
  }

  /// `POST /me/businesses/{businessId}/services`
  Future<AgendaService> createService({
    required String businessId,
    required String nombre,
    String? descripcion,
    required int duracionMin,
    required double precio,
    String schedulingMode = 'GENERAL',
    List<String>? staffMemberIds,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/me/businesses/$businessId/services'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            if (descripcion != null) 'descripcion': descripcion,
            'duracionMin': duracionMin,
            'precio': precio,
            'schedulingMode': schedulingMode,
            if (staffMemberIds != null) 'staffMemberIds': staffMemberIds,
          }),
        ));
    return _decode(r, (body) => AgendaService.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /me/businesses/{businessId}/services/{serviceId}`
  Future<AgendaService> updateService({
    required String businessId,
    required String serviceId,
    required String nombre,
    String? descripcion,
    required int duracionMin,
    required double precio,
    required bool activo,
    String schedulingMode = 'GENERAL',
    List<String>? staffMemberIds,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/me/businesses/$businessId/services/$serviceId'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            if (descripcion != null) 'descripcion': descripcion,
            'duracionMin': duracionMin,
            'precio': precio,
            'activo': activo,
            'schedulingMode': schedulingMode,
            if (staffMemberIds != null) 'staffMemberIds': staffMemberIds,
          }),
        ));
    return _decode(r, (body) => AgendaService.fromJson(body as Map<String, dynamic>));
  }

  /// `DELETE /me/businesses/{businessId}/services/{serviceId}`
  Future<void> deleteService({
    required String businessId,
    required String serviceId,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/me/businesses/$businessId/services/$serviceId'),
          headers: _headers(),
        ));
    _ensureOk(r);
  }

  // =====================================================================
  // ME — plans
  // =====================================================================

  /// `GET /me/businesses/{businessId}/plans`
  Future<List<Plan>> listPlans({
    required String businessId,
    bool onlyActive = false,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/me/businesses/$businessId/plans', {
            if (onlyActive) 'onlyActive': 'true',
          }),
          headers: _headers(),
        ));
    return _decodeList(r, Plan.fromJson);
  }

  /// `POST /me/businesses/{businessId}/plans`
  Future<Plan> createPlan({
    required String businessId,
    required String nombrePlan,
    required PlanTipo tipo,
    PlanTier? tier,
    required int totalCreditos,
    required int validezDias,
    required double precio,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/me/businesses/$businessId/plans'),
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

  /// `PUT /me/businesses/{businessId}/plans/{planId}`
  Future<Plan> updatePlan({
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
          _uri('/me/businesses/$businessId/plans/$planId'),
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

  /// `DELETE /me/businesses/{businessId}/plans/{planId}`
  Future<void> deletePlan({
    required String businessId,
    required String planId,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/me/businesses/$businessId/plans/$planId'),
          headers: _headers(),
        ));
    _ensureOk(r);
  }

  // =====================================================================
  // ME — loyalty suggestions
  // =====================================================================

  /// `GET /me/businesses/{businessId}/loyalty/suggestions`
  Future<List<LoyaltySuggestion>> listLoyaltySuggestions({
    required String businessId,
    LoyaltySuggestionEstado? estado,
  }) async {
    final r = await _send(() => _client.get(
          _uri(
            '/me/businesses/$businessId/loyalty/suggestions',
            {if (estado != null) 'estado': estado.toBackendString()},
          ),
          headers: _headers(),
        ));
    return _decodeList(r, LoyaltySuggestion.fromJson);
  }

  /// `PATCH /me/businesses/{businessId}/loyalty/suggestions/{id}`
  Future<LoyaltySuggestion> patchLoyaltySuggestion({
    required String businessId,
    required String id,
    required LoyaltySuggestionEstado estado,
  }) async {
    final r = await _send(() => _client.patch(
          _uri('/me/businesses/$businessId/loyalty/suggestions/$id'),
          headers: _headers(),
          body: jsonEncode({'estado': estado.toBackendString()}),
        ));
    return _decode(r, (body) => LoyaltySuggestion.fromJson(body as Map<String, dynamic>));
  }

  /// `POST /me/businesses/{businessId}/loyalty/suggestions/{id}/send`
  Future<LoyaltySuggestion> sendLoyaltySuggestion({
    required String businessId,
    required String id,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/me/businesses/$businessId/loyalty/suggestions/$id/send'),
          headers: _headers(),
        ));
    return _decode(r, (body) => LoyaltySuggestion.fromJson(body as Map<String, dynamic>));
  }

  // =====================================================================
  // ME — notification templates
  // =====================================================================

  /// `GET /me/businesses/{businessId}/notification-templates`
  Future<List<NotificationTemplate>> listTemplates({
    required String businessId,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/me/businesses/$businessId/notification-templates'),
          headers: _headers(),
        ));
    return _decodeList(r, NotificationTemplate.fromJson);
  }

  /// `POST /me/businesses/{businessId}/notification-templates`
  Future<NotificationTemplate> createTemplate({
    required String businessId,
    required String codigo,
    required NotificationCanal canal,
    required String titulo,
    required String cuerpo,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/me/businesses/$businessId/notification-templates'),
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

  /// `PUT /me/businesses/{businessId}/notification-templates/{id}`
  Future<NotificationTemplate> updateTemplate({
    required String businessId,
    required String id,
    required String codigo,
    required String titulo,
    required String cuerpo,
    required NotificationCanal canal,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/me/businesses/$businessId/notification-templates/$id'),
          headers: _headers(),
          body: jsonEncode({
            'codigo': codigo,
            'titulo': titulo,
            'cuerpo': cuerpo,
            'canal': canal.toBackendString(),
          }),
        ));
    return _decode(r, (body) => NotificationTemplate.fromJson(body as Map<String, dynamic>));
  }

  /// `DELETE /me/businesses/{businessId}/notification-templates/{id}`
  Future<void> deleteTemplate({
    required String businessId,
    required String id,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/me/businesses/$businessId/notification-templates/$id'),
          headers: _headers(),
        ));
    _ensureOk(r);
  }

  // =====================================================================
  // ME — subscriptions
  // =====================================================================

  /// `POST /me/businesses/{businessId}/subscriptions`
  Future<Subscription> purchaseSubscription({
    required String businessId,
    required String planId,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/me/businesses/$businessId/subscriptions'),
          headers: _headers(sendUserId: true),
          body: jsonEncode({'planId': planId}),
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

  /// `POST /me/businesses/{businessId}/bookings`
  Future<Booking> createBooking({
    required String businessId,
    required String serviceId,
    required DateTime fechaHoraInicio,
    BookingTipo tipoReserva = BookingTipo.pagoPorTurno,
    String? subscriptionId,
    String? notas,
    String? idempotencyKey,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/me/businesses/$businessId/bookings'),
          headers: _headers(sendUserId: true, idempotencyKey: idempotencyKey),
          body: jsonEncode({
            'serviceId': serviceId,
            'fechaHoraInicio': fechaHoraInicio.toIso8601String(),
            'tipoReserva': tipoReserva.toBackendString(),
            if (subscriptionId != null) 'subscriptionId': subscriptionId,
            if (notas != null && notas.isNotEmpty) 'notas': notas,
          }),
        ));
    return _decode(r, (body) => Booking.fromJson(body as Map<String, dynamic>));
  }

  /// `GET /me/businesses/{businessId}/bookings`
  Future<List<Booking>> myBookings({
    String? businessId,
    BookingEstado? estado,
  }) async {
    if (businessId == null || businessId.isEmpty) {
      throw const AgendaApiException(
        message: 'Falta businessId para listar turnos.',
        status: 400,
        code: 'MISSING_BUSINESS_ID',
      );
    }
    final r = await _send(() => _client.get(
          _uri('/me/businesses/$businessId/bookings', {
            if (estado != null) 'estado': estado.name.toUpperCase(),
          }),
          headers: _headers(sendUserId: true),
        ));
    return _decodeList(r, Booking.fromJson);
  }

  /// `GET /me/businesses/{businessId}/agenda/bookings?from=...&to=...`
  ///
  /// Calendario privado del negocio (admin). No requiere `X-User-Id`.
  Future<List<Booking>> businessAgendaBookings({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/me/businesses/$businessId/agenda/bookings', {
            'from': from.toIso8601String(),
            'to': to.toIso8601String(),
          }),
          headers: _headers(),
        ));
    return _decodeList(r, Booking.fromJson);
  }

  /// `DELETE /me/businesses/{businessId}/bookings/{bookingId}`
  Future<void> cancelBooking({
    required String businessId,
    required String bookingId,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/me/businesses/$businessId/bookings/$bookingId'),
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
  // ME — staff members
  // =====================================================================

  /// `GET /me/businesses/{businessId}/staff`
  Future<List<StaffMember>> getStaffMembers({
    required String businessId,
  }) async {
    final r = await _send(() => _client.get(
          _uri('/me/businesses/$businessId/staff'),
          headers: _headers(),
        ));
    return _decodeList(r, StaffMember.fromJson);
  }

  /// `POST /me/businesses/{businessId}/staff`
  Future<StaffMember> createStaffMember({
    required String businessId,
    required String nombre,
    String? rol,
    String? avatarUrl,
    String? telefono,
    String? color,
  }) async {
    final r = await _send(() => _client.post(
          _uri('/me/businesses/$businessId/staff'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            if (rol != null && rol.isNotEmpty) 'rol': rol,
            if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
            if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
            if (color != null && color.isNotEmpty) 'color': color,
          }),
        ));
    return _decode(r, (body) => StaffMember.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /me/businesses/{businessId}/staff/{staffId}`
  Future<StaffMember> updateStaffMember({
    required String businessId,
    required String staffId,
    required String nombre,
    String? rol,
    String? avatarUrl,
    String? telefono,
    String? email,
    String? bio,
    String? color,
    required String status,
    Map<String, dynamic>? customSchedule,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/me/businesses/$businessId/staff/$staffId'),
          headers: _headers(),
          body: jsonEncode({
            'nombre': nombre,
            if (rol != null && rol.isNotEmpty) 'rol': rol,
            if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
            if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
            if (email != null && email.isNotEmpty) 'email': email,
            if (bio != null && bio.isNotEmpty) 'bio': bio,
            if (color != null && color.isNotEmpty) 'color': color,
            'status': status,
            if (customSchedule != null) 'customSchedule': customSchedule,
          }),
        ));
    return _decode(r, (body) => StaffMember.fromJson(body as Map<String, dynamic>));
  }

  /// `PUT /me/businesses/{businessId}/staff/{staffId}/services`
  Future<StaffMember> updateStaffServices({
    required String businessId,
    required String staffId,
    required List<String> serviceIds,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/me/businesses/$businessId/staff/$staffId/services'),
          headers: _headers(),
          body: jsonEncode({'serviceIds': serviceIds}),
        ));
    return _decode(r, (body) => StaffMember.fromJson(body as Map<String, dynamic>));
  }

  /// `DELETE /me/businesses/{businessId}/staff/{staffId}` → 204
  Future<void> deleteStaffMember({
    required String businessId,
    required String staffId,
  }) async {
    final r = await _send(() => _client.delete(
          _uri('/me/businesses/$businessId/staff/$staffId'),
          headers: _headers(),
        ));
    _ensureOk(r);
  }

  /// `PUT /me/bots/{botId}/linked-businesses` → 204
  Future<void> replaceBotLinkedBusinesses({
    required int botId,
    required List<String> businessIds,
  }) async {
    final r = await _send(() => _client.put(
          _uri('/me/bots/$botId/linked-businesses'),
          headers: _headers(),
          body: jsonEncode({'businessIds': businessIds}),
        ));
    _ensureOk(r);
  }

  /// Cierra el http client subyacente (testing).
  void close() => _client.close();
}

/// Formats a [DateTime] as `"yyyy-MM-ddTHH:mm:ss"` (no sub-seconds, no timezone)
/// so Java's LocalDateTime parser accepts it without issues.
String _fmtLocalDateTime(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final mo = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final mi = dt.minute.toString().padLeft(2, '0');
  return '$y-$mo-${d}T$h:$mi:00';
}
