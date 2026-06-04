import 'package:botai_admin/models/agenda/agenda_notification.dart';
import 'package:botai_admin/models/agenda/agenda_service.dart';
import 'package:botai_admin/models/agenda/availability_slot.dart';
import 'package:botai_admin/models/agenda/business_hours.dart';
import 'package:botai_admin/models/agenda/business_photo.dart';
import 'package:botai_admin/models/agenda/booking.dart';
import 'package:botai_admin/models/agenda/business.dart';
import 'package:botai_admin/models/agenda/business_settings.dart';
import 'package:botai_admin/models/agenda/business_summary.dart';
import 'package:botai_admin/models/agenda/category.dart';
import 'package:botai_admin/models/agenda/loyalty_suggestion.dart';
import 'package:botai_admin/models/agenda/notification_template.dart';
import 'package:botai_admin/models/agenda/plan.dart';
import 'package:botai_admin/models/agenda/public_client_profile.dart';
import 'package:botai_admin/models/agenda/register_tenant.dart';
import 'package:botai_admin/models/agenda/staff_member.dart';
import 'package:botai_admin/models/agenda/tenant_admin_context.dart';
import 'package:botai_admin/models/agenda/subscription.dart';
import 'package:botai_admin/models/agenda/tenant_features.dart';
import 'package:botai_admin/models/agenda/wallet.dart';
import 'package:botai_admin/services/agenda_api_exception.dart';
import 'package:botai_admin/services/agenda_api_service.dart';

/// Stub controlable de [AgendaApiService] para widget tests.
class FakeAgendaApiService implements AgendaApiService {
  // --- Public ---
  List<BusinessSummary>? nextSearchResults;
  List<Category>? nextCategories;

  // --- Platform ---
  List<Category>? nextPlatformCategories;

  // --- Tenant ---
  List<Business>? nextBusinesses;
  List<AgendaService>? nextServices;
  List<Plan>? nextPlans;
  BusinessSettings? nextSettings;
  TenantFeatures? nextFeatures;
  List<LoyaltySuggestion>? nextLoyaltySuggestions;
  List<NotificationTemplate>? nextTemplates;

  // --- Me ---
  List<Subscription>? nextSubscriptions;
  Wallet? nextWallet;
  List<Booking>? nextBookings;
  List<AgendaNotification>? nextNotifications;
  Booking? nextCreatedBooking;

  AgendaApiException? throwNext;

  final List<({String nombre, String slug, List<String> synonyms, bool activo})>
      createdCategories = [];
  final List<String> deletedCategoryIds = [];
  final List<String> createdBusinessNames = [];
  final List<String> deletedServiceIds = [];
  final List<String> deletedPlanIds = [];
  final List<String> cancelledBookingIds = [];
  final List<String> deletedTemplateIds = [];

  @override
  String get baseUrl => 'http://test/api/agenda';

  @override
  void setAccessToken(String? token) {}

  @override
  void setRefreshAccessTokenCallback(Future<String?> Function()? cb) {
    // No-op en tests: el fake no hace requests HTTP reales.
  }

  String? _fakeUserId;

  @override
  void setUserId(String? userId) => _fakeUserId = userId;

  @override
  String? get userId => _fakeUserId;

  @override
  void close() {}

  void _maybeThrow() {
    final ex = throwNext;
    if (ex != null) {
      throwNext = null;
      throw ex;
    }
  }

  // ── public — registro ────────────────────────────────────────────────────

  RegisterTenantResponse? nextRegisterResult;

  @override
  Future<RegisterTenantResponse> registerTenant({
    required String nombrePropietario,
    String? email,
    String? numero,
    String? telefono,
    required String nombreNegocio,
    String? categoriaSlug,
  }) async {
    _maybeThrow();
    return nextRegisterResult ??
        RegisterTenantResponse(
          tenantId: 'tenant-test-uuid',
          businessId: 'business-test-uuid',
          accessCode: 'TESTCODE',
        );
  }

  TenantAdminContext? nextTenantAdminContext;

  @override
  Future<TenantAdminContext> fetchTenantAdminContext() async {
    _maybeThrow();
    final v = nextTenantAdminContext;
    if (v == null) {
      throw const AgendaApiException(
        message: 'Sin tenant para este admin',
        status: 404,
      );
    }
    return v;
  }

  TenantAdminContext? nextLinkTenantResult;

  @override
  Future<TenantAdminContext> linkTenantAdminWithAccessCode(String accessCode) async {
    _maybeThrow();
    return nextLinkTenantResult ??
        TenantAdminContext(tenantId: 'linked-via-$accessCode');
  }

  TenantAdminContext? nextLinkIdentifierResult;

  @override
  Future<TenantAdminContext> linkTenantIdentifier({
    String? email,
    String? numero,
  }) async {
    _maybeThrow();
    return nextLinkIdentifierResult ?? const TenantAdminContext(tenantId: 'tenant-test-uuid');
  }

  @override
  Future<Map<String, String>> mePublicLink() async {
    _maybeThrow();
    return const {
      'slug': 'fake-slug',
      'url': 'https://fake.example/agenda/fake-slug',
      'businessId': 'business-test-uuid',
    };
  }

  @override
  Future<String> resolvePublicSlug(String slug) async {
    _maybeThrow();
    return 'business-test-uuid';
  }

  // ── public ───────────────────────────────────────────────────────────────

  String? nextTenantByCode;

  @override
  Future<String> getTenantByCode(String accessCode) async {
    _maybeThrow();
    return nextTenantByCode ?? 'tenant-test-uuid';
  }

  @override
  Future<List<BusinessSummary>> search({
    required String q,
    String? tenantId,
    String? categorySlug,
  }) async {
    _maybeThrow();
    return nextSearchResults ?? const [];
  }

  @override
  Future<List<Category>> listPublicCategories() async {
    _maybeThrow();
    return nextCategories ?? const [];
  }

  @override
  Future<List<BusinessSummary>> businessesByCategory({
    required String slug,
    String? tenantId,
  }) async {
    _maybeThrow();
    return nextSearchResults ?? const [];
  }

  @override
  Future<Business> publicBusinessDetail(String id) async {
    _maybeThrow();
    return Business(
      id: id,
      tenantId: 't',
      nombre: 'Negocio fake',
      searchTags: const [],
      activo: true,
    );
  }

  @override
  Future<List<StaffMember>> publicBusinessStaff(String id) async {
    _maybeThrow();
    return const [];
  }

  @override
  Future<List<AvailabilitySlot>> publicAvailability({
    required String businessId,
    required String serviceId,
    String? staffMemberId,
    required String date,
  }) async {
    _maybeThrow();
    return const [];
  }

  @override
  Future<List<AgendaService>> publicBusinessServices(String id) async {
    _maybeThrow();
    return const [];
  }

  @override
  Future<Booking> publicCreateBooking({
    required String businessId,
    required String serviceId,
    String? staffMemberId,
    required DateTime fechaHoraInicio,
    String? clientId,
    String? nombreCliente,
    String? emailCliente,
    String? telefonoCliente,
    String? clientSessionToken,
    String? notas,
  }) async {
    _maybeThrow();
    return nextCreatedBooking ??
        Booking(
          id: 'booking-public-1',
          userId: 'user-public-1',
          serviceId: serviceId,
          servicioNombre: 'Servicio test',
          businessId: businessId,
          fechaHoraInicio: fechaHoraInicio,
          fechaHoraFin: fechaHoraInicio.add(const Duration(minutes: 60)),
          estado: BookingEstado.pendiente,
          tipoReserva: BookingTipo.pagoPorTurno,
        );
  }

  @override
  Future<SendPhoneVerificationResult> sendPublicPhoneVerification({
    required String businessId,
    required String telefono,
  }) async {
    _maybeThrow();
    return const SendPhoneVerificationResult(sent: true, message: 'Código enviado');
  }

  @override
  Future<VerifyPublicPhoneResult> verifyPublicPhoneCode({
    required String businessId,
    required String telefono,
    required String code,
  }) async {
    _maybeThrow();
    return VerifyPublicPhoneResult(
      clientSessionToken: 'fake-session-token',
      client: PublicClientProfile(
        id: 'user-public-1',
        nombre: 'Cliente test',
        telefono: telefono,
        needsName: false,
      ),
      bookings: nextBookings ?? const [],
    );
  }

  @override
  Future<List<Booking>> listPublicClientBookings({
    required String sessionToken,
    required String businessId,
  }) async {
    _maybeThrow();
    return nextBookings ?? const [];
  }

  @override
  Future<PublicClientProfile> updatePublicClientProfile({
    required String sessionToken,
    required String nombre,
  }) async {
    _maybeThrow();
    return PublicClientProfile(
      id: 'user-public-1',
      nombre: nombre,
      telefono: '59899123456',
      needsName: false,
    );
  }

  @override
  Future<Business> publicBusinessDetailBySlug(String slug) async {
    _maybeThrow();
    return Business(
      id: 'business-test-uuid',
      tenantId: 't',
      nombre: 'Negocio fake ($slug)',
      searchTags: const [],
      activo: true,
    );
  }

  @override
  Future<List<AgendaService>> publicBusinessServicesBySlug(String slug) async {
    _maybeThrow();
    return const [];
  }

  @override
  Future<List<StaffMember>> publicBusinessStaffBySlug(String slug) async {
    _maybeThrow();
    return const [];
  }

  @override
  Future<List<AvailabilitySlot>> publicAvailabilityBySlug({
    required String slug,
    required String serviceId,
    String? staffMemberId,
    required String date,
  }) async {
    _maybeThrow();
    return const [];
  }

  // ── platform ─────────────────────────────────────────────────────────────

  @override
  Future<List<Category>> listAllCategories() async {
    _maybeThrow();
    return nextPlatformCategories ?? const [];
  }

  @override
  Future<Category> createCategory({
    required String nombre,
    required String slug,
    required List<String> synonyms,
    bool activo = true,
  }) async {
    _maybeThrow();
    createdCategories
        .add((nombre: nombre, slug: slug, synonyms: synonyms, activo: activo));
    return Category(
      id: 'new-${createdCategories.length}',
      nombre: nombre,
      slug: slug,
      synonyms: synonyms,
      activo: activo,
    );
  }

  @override
  Future<Category> updateCategory({
    required String id,
    required String nombre,
    required String slug,
    required List<String> synonyms,
    required bool activo,
  }) async {
    _maybeThrow();
    return Category(id: id, nombre: nombre, slug: slug, synonyms: synonyms, activo: activo);
  }

  @override
  Future<Category> mergeCategorySynonyms({
    required String id,
    required List<String> synonyms,
  }) async {
    _maybeThrow();
    return Category(id: id, nombre: '', slug: '', synonyms: synonyms, activo: true);
  }

  @override
  Future<void> deleteCategory(String id) async {
    _maybeThrow();
    deletedCategoryIds.add(id);
  }

  // ── me — features ───────────────────────────────────────────────────────

  @override
  Future<TenantFeatures> getFeatures() async {
    _maybeThrow();
    return nextFeatures ??
        TenantFeatures(
          tenantId: 'me',
          agendaEnabled: true,
          publicSearchEnabled: true,
          loyaltyEngineEnabled: false,
          autoNotifications: false,
        );
  }

  @override
  Future<TenantFeatures> updateFeatures(
      TenantFeatures features) async {
    _maybeThrow();
    return features;
  }

  // ── tenant — business hours ──────────────────────────────────────────────

  @override
  Future<List<BusinessHours>> getBusinessHours({
    required String businessId,
  }) async {
    _maybeThrow();
    return const [];
  }

  @override
  Future<List<BusinessHours>> saveBusinessHours({
    required String businessId,
    required List<BusinessHours> hours,
  }) async {
    _maybeThrow();
    return hours;
  }

  // ── me — businesses ─────────────────────────────────────────────────────

  @override
  Future<List<Business>> listBusinesses() async {
    _maybeThrow();
    return nextBusinesses ?? const [];
  }

  @override
  Future<Business> createBusiness({
    required String nombre,
    String? descripcion,
    List<String> searchTags = const [],
    String? ownerUserId,
  }) async {
    _maybeThrow();
    createdBusinessNames.add(nombre);
    return Business(
      id: 'biz-${createdBusinessNames.length}',
      tenantId: 'me',
      nombre: nombre,
      descripcion: descripcion,
      ownerUserId: ownerUserId,
      searchTags: searchTags,
      activo: true,
    );
  }

  @override
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
    _maybeThrow();
    return Business(
      id: businessId,
      tenantId: 'me',
      nombre: nombre,
      descripcion: descripcion,
      searchTags: searchTags,
      activo: true,
      logoUrl: logoUrl,
      colorPrimario: colorPrimario,
      instagramUrl: instagramUrl,
      tiktokUrl: tiktokUrl,
      facebookUrl: facebookUrl,
      colorFondo: colorFondo,
      fontFamily: fontFamily,
    );
  }

  @override
  Future<String> uploadBusinessAvatar({
    required String businessId,
    required List<int> bytes,
    required String fileName,
  }) async {
    _maybeThrow();
    return 'https://fake.example/avatar-business-$businessId';
  }

  @override
  Future<String> uploadStaffAvatar({
    required String businessId,
    required String staffId,
    required List<int> bytes,
    required String fileName,
  }) async {
    _maybeThrow();
    return 'https://fake.example/avatar-staff-$staffId';
  }

  @override
  Future<void> associateCategories({
    
    required String businessId,
    required List<String> categoryIds,
  }) async {
    _maybeThrow();
  }

  List<BusinessPhoto>? nextBusinessPhotos;
  int _fakePhotoSeq = 0;

  @override
  Future<List<BusinessPhoto>> getBusinessPhotos({
    
    required String businessId,
  }) async {
    _maybeThrow();
    return nextBusinessPhotos ?? const [];
  }

  @override
  Future<BusinessPhoto> addBusinessPhoto({
    
    required String businessId,
    required String url,
  }) async {
    _maybeThrow();
    _fakePhotoSeq += 1;
    return BusinessPhoto(
      id: 'photo-$_fakePhotoSeq',
      businessId: businessId,
      url: url,
      orden: _fakePhotoSeq,
    );
  }

  @override
  Future<void> deleteBusinessPhoto({
    
    required String businessId,
    required String photoId,
  }) async {
    _maybeThrow();
  }

  @override
  Future<BusinessSettings> getSettings({
    required String businessId,
  }) async {
    _maybeThrow();
    return nextSettings ??
        BusinessSettings(
          businessId: businessId,
          hoursCancellationLimit: 24,
          loyaltyMinAttendances: 5,
          loyaltyWindowDays: 30,
          expirationAlertDays: 7,
          expirationAlertCredits: 2,
          autoNotifyEnabled: false,
        );
  }

  @override
  Future<BusinessSettings> updateSettings({
    required String businessId,
    required BusinessSettings settings,
  }) async {
    _maybeThrow();
    return settings;
  }

  // ── me — services ───────────────────────────────────────────────────────

  @override
  Future<List<AgendaService>> listTenantServices({
    required String businessId,
    bool soloActivos = false,
  }) async {
    _maybeThrow();
    return nextServices ?? const [];
  }

  @override
  Future<AgendaService> createService({
    required String businessId,
    required String nombre,
    String? descripcion,
    required int duracionMin,
    required double precio,
  }) async {
    _maybeThrow();
    return AgendaService(
      id: 'svc-1',
      businessId: businessId,
      nombre: nombre,
      descripcion: descripcion,
      duracionMin: duracionMin,
      precio: precio,
      activo: true,
    );
  }

  @override
  Future<AgendaService> updateService({
    required String businessId,
    required String serviceId,
    required String nombre,
    String? descripcion,
    required int duracionMin,
    required double precio,
    required bool activo,
  }) async {
    _maybeThrow();
    return AgendaService(
      id: serviceId,
      businessId: businessId,
      nombre: nombre,
      descripcion: descripcion,
      duracionMin: duracionMin,
      precio: precio,
      activo: activo,
    );
  }

  @override
  Future<void> deleteService({
    required String businessId,
    required String serviceId,
  }) async {
    _maybeThrow();
    deletedServiceIds.add(serviceId);
  }

  // ── me — plans ─────────────────────────────────────────────────────────

  @override
  Future<List<Plan>> listPlans({
    required String businessId,
    bool onlyActive = false,
  }) async {
    _maybeThrow();
    return nextPlans ?? const [];
  }

  @override
  Future<Plan> createPlan({
    required String businessId,
    required String nombrePlan,
    required PlanTipo tipo,
    PlanTier? tier,
    required int totalCreditos,
    required int validezDias,
    required double precio,
  }) async {
    _maybeThrow();
    return Plan(
      id: 'plan-1',
      businessId: businessId,
      nombrePlan: nombrePlan,
      tipo: tipo,
      tier: tier,
      totalCreditos: totalCreditos,
      validezDias: validezDias,
      precio: precio,
      activo: true,
    );
  }

  @override
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
    _maybeThrow();
    return Plan(
      id: planId,
      businessId: businessId,
      nombrePlan: nombrePlan,
      tipo: tipo,
      tier: tier,
      totalCreditos: totalCreditos,
      validezDias: validezDias,
      precio: precio,
      activo: activo,
    );
  }

  @override
  Future<void> deletePlan({
    required String businessId,
    required String planId,
  }) async {
    _maybeThrow();
    deletedPlanIds.add(planId);
  }

  // ── tenant — loyalty ─────────────────────────────────────────────────────

  @override
  Future<List<LoyaltySuggestion>> listLoyaltySuggestions({
    required String businessId,
    LoyaltySuggestionEstado? estado,
  }) async {
    _maybeThrow();
    return nextLoyaltySuggestions ?? const [];
  }

  @override
  Future<LoyaltySuggestion> patchLoyaltySuggestion({
    required String businessId,
    required String id,
    required LoyaltySuggestionEstado estado,
  }) async {
    _maybeThrow();
    return LoyaltySuggestion(
      id: id,
      businessId: businessId,
      userId: 'user-1',
      triggerRule: 'test-rule',
      estado: estado,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<LoyaltySuggestion> sendLoyaltySuggestion({
    required String businessId,
    required String id,
  }) async {
    _maybeThrow();
    return LoyaltySuggestion(
      id: id,
      businessId: businessId,
      userId: 'user-1',
      triggerRule: 'test-rule',
      estado: LoyaltySuggestionEstado.enviada,
      createdAt: DateTime.now(),
    );
  }

  // ── tenant — templates ───────────────────────────────────────────────────

  @override
  Future<List<NotificationTemplate>> listTemplates({
    required String businessId,
  }) async {
    _maybeThrow();
    return nextTemplates ?? const [];
  }

  @override
  Future<NotificationTemplate> createTemplate({
    required String businessId,
    required String codigo,
    required NotificationCanal canal,
    required String titulo,
    required String cuerpo,
  }) async {
    _maybeThrow();
    return NotificationTemplate(
      id: 'tpl-1',
      businessId: businessId,
      codigo: codigo,
      canal: canal,
      titulo: titulo,
      cuerpo: cuerpo,
    );
  }

  @override
  Future<NotificationTemplate> updateTemplate({
    required String businessId,
    required String id,
    required String codigo,
    required String titulo,
    required String cuerpo,
    required NotificationCanal canal,
  }) async {
    _maybeThrow();
    return NotificationTemplate(
      id: id,
      businessId: businessId,
      codigo: codigo,
      canal: canal,
      titulo: titulo,
      cuerpo: cuerpo,
    );
  }

  @override
  Future<void> deleteTemplate({
    required String businessId,
    required String id,
  }) async {
    _maybeThrow();
    deletedTemplateIds.add(id);
  }

  // ── me — subscriptions ───────────────────────────────────────────────────

  @override
  Future<Subscription> purchaseSubscription({
    required String businessId,
    required String planId,
  }) async {
    _maybeThrow();
    return Subscription(
      id: 'sub-1',
      userId: 'user-1',
      planId: planId,
      businessId: businessId,
      saldoActual: 10,
      fechaInicio: DateTime.now(),
      estado: SubscriptionEstado.activa,
    );
  }

  @override
  Future<List<Subscription>> mySubscriptions({bool onlyActive = false}) async {
    _maybeThrow();
    final items = nextSubscriptions ?? const [];
    if (onlyActive) return items.where((s) => s.estado.isActive).toList();
    return items;
  }

  @override
  Future<Wallet> myWallet(String subscriptionId) async {
    _maybeThrow();
    return nextWallet ??
        Wallet(
          subscriptionId: subscriptionId,
          saldoActual: 10,
          movimientos: const [],
        );
  }

  // ── me — bookings ─────────────────────────────────────────────────────────

  @override
  Future<Booking> createBooking({
    required String businessId,
    required String serviceId,
    required DateTime fechaHoraInicio,
    BookingTipo tipoReserva = BookingTipo.pagoPorTurno,
    String? subscriptionId,
    String? notas,
    String? idempotencyKey,
  }) async {
    _maybeThrow();
    return nextCreatedBooking ??
        Booking(
          id: 'booking-1',
          userId: 'user-1',
          serviceId: serviceId,
          servicioNombre: 'Servicio test',
          businessId: businessId,
          fechaHoraInicio: fechaHoraInicio,
          fechaHoraFin: fechaHoraInicio.add(const Duration(minutes: 60)),
          estado: BookingEstado.confirmada,
          tipoReserva: tipoReserva,
        );
  }

  @override
  Future<List<Booking>> myBookings({
    String? tenantId,
    String? businessId,
    BookingEstado? estado,
  }) async {
    _maybeThrow();
    return nextBookings ?? const [];
  }

  @override
  Future<List<Booking>> businessAgendaBookings({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    _maybeThrow();
    return nextBookings ?? const [];
  }

  @override
  Future<void> cancelBooking({
    
    required String businessId,
    required String bookingId,
  }) async {
    _maybeThrow();
    cancelledBookingIds.add(bookingId);
  }

  // ── me — notifications ───────────────────────────────────────────────────

  @override
  Future<List<AgendaNotification>> myNotifications({
    NotificationEstado? estado,
  }) async {
    _maybeThrow();
    return nextNotifications ?? const [];
  }

  List<StaffMember>? nextStaffMembers;

  @override
  Future<List<StaffMember>> getStaffMembers({
    
    required String businessId,
  }) async {
    _maybeThrow();
    return nextStaffMembers ?? const [];
  }

  @override
  Future<StaffMember> createStaffMember({
    
    required String businessId,
    required String nombre,
    String? rol,
    String? avatarUrl,
  }) async {
    _maybeThrow();
    return StaffMember(
      id: 'staff-new',
      businessId: businessId,
      nombre: nombre,
      rol: rol,
      avatarUrl: avatarUrl,
      activo: true,
    );
  }

  @override
  Future<StaffMember> updateStaffMember({
    
    required String businessId,
    required String staffId,
    required String nombre,
    String? rol,
    String? avatarUrl,
    required bool activo,
  }) async {
    _maybeThrow();
    return StaffMember(
      id: staffId,
      businessId: businessId,
      nombre: nombre,
      rol: rol,
      avatarUrl: avatarUrl,
      activo: activo,
    );
  }

  @override
  Future<void> deleteStaffMember({
    
    required String businessId,
    required String staffId,
  }) async {
    _maybeThrow();
  }
}
