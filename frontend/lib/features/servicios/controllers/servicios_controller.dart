import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/service_scheduling_mode.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/public/public_categories_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../services/agenda_api_exception.dart';
import '../models/business_category.dart';
import '../models/service_stats.dart';
import '../models/servicio_item.dart';

// ─── Key ──────────────────────────────────────────────────────────────────────

typedef ServiciosKey = ({String tenantId, String businessId});

// ─── Filter enum ──────────────────────────────────────────────────────────────

enum ServicioFilter { all, active, inactive }

// ─── UI-only extras (not in backend model yet) ────────────────────────────────

class ServicioExtras {
  final bool flexibleDuration;
  final bool priceFrom;
  final ServiceSchedulingMode schedulingMode;
  final List<String> professionalIds;

  const ServicioExtras({
    this.flexibleDuration = false,
    this.priceFrom = false,
    this.schedulingMode = ServiceSchedulingMode.general,
    this.professionalIds = const [],
  });

  ServicioExtras copyWith({
    bool? flexibleDuration,
    bool? priceFrom,
    ServiceSchedulingMode? schedulingMode,
    List<String>? professionalIds,
  }) =>
      ServicioExtras(
        flexibleDuration: flexibleDuration ?? this.flexibleDuration,
        priceFrom: priceFrom ?? this.priceFrom,
        schedulingMode: schedulingMode ?? this.schedulingMode,
        professionalIds: professionalIds ?? this.professionalIds,
      );
}

// ─── State ────────────────────────────────────────────────────────────────────

class ServiciosState {
  final List<ServicioItem> items;
  final List<StaffMember> staff;
  final ServicioFilter filter;
  final String query;
  final List<BusinessCategory> categories;
  final bool isLoading;
  final String? error;

  const ServiciosState({
    this.items = const [],
    this.staff = const [],
    this.filter = ServicioFilter.all,
    this.query = '',
    this.categories = const [BusinessCategory.otra],
    this.isLoading = false,
    this.error,
  });

  ServiciosState copyWith({
    List<ServicioItem>? items,
    List<StaffMember>? staff,
    ServicioFilter? filter,
    String? query,
    List<BusinessCategory>? categories,
    bool? isLoading,
    Object? error = _sentinel,
  }) =>
      ServiciosState(
        items: items ?? this.items,
        staff: staff ?? this.staff,
        filter: filter ?? this.filter,
        query: query ?? this.query,
        categories: categories ?? this.categories,
        isLoading: isLoading ?? this.isLoading,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );

  static const _sentinel = Object();

  /// Primera categoría (fallback `otra` si la lista está vacía).
  BusinessCategory get primaryCategory =>
      categories.isEmpty ? BusinessCategory.otra : categories.first;

  /// `true` si la única categoría es `otra` — gatilla el modo "desde cero" directo.
  bool get isOnlyOtra =>
      categories.length == 1 && categories.first == BusinessCategory.otra;

  int get countActive => items.where((s) => s.active).length;
  int get countInactive => items.where((s) => !s.active).length;
  int get totalBookingsThisMonth => 0;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ServiciosNotifier extends StateNotifier<ServiciosState> {
  ServiciosNotifier(this._ref, this._key)
      : super(const ServiciosState(isLoading: true)) {
    _ref.listen<BusinessesState>(
      businessesProvider(_key.tenantId),
      (_, next) => _syncCategoryFromBusiness(next.items),
      fireImmediately: true,
    );
    _load();
  }

  final Ref _ref;
  final ServiciosKey _key;

  void _syncCategoryFromBusiness(List<Business> businesses) {
    final business =
        businesses.where((b) => b.id == _key.businessId).firstOrNull;
    if (business == null || business.categorias.isEmpty) return;
    final seen = <BusinessCategory>{};
    final cats = <BusinessCategory>[];
    for (final slug in business.categorias) {
      final c = BusinessCategory.fromSlug(slug);
      if (seen.add(c)) cats.add(c);
    }
    if (cats.isEmpty) return;
    if (!_listEquals(state.categories, cats)) {
      state = state.copyWith(categories: cats);
    }
  }

  bool _listEquals(List<BusinessCategory> a, List<BusinessCategory> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  final Map<String, ServicioExtras> _extras = {};

  Future<void> reload() => _load();

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final results = await Future.wait([
        api.listTenantServices(businessId: _key.businessId),
        api.getStaffMembers(businessId: _key.businessId),
      ]);

      final services = results[0] as List<AgendaService>;
      final staff = results[1] as List<StaffMember>;

      for (final service in services) {
        final prev = _extras[service.id];
        _extras[service.id] = ServicioExtras(
          flexibleDuration: prev?.flexibleDuration ?? false,
          priceFrom: prev?.priceFrom ?? false,
          schedulingMode: service.schedulingMode,
          professionalIds: service.staffMemberIds,
        );
      }

      state = state.copyWith(
        items: services.map((s) => _toItem(s)).toList(),
        staff: staff,
        isLoading: false,
      );
    } on AgendaApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  ServicioItem _toItem(AgendaService s) {
    final extras = _extras[s.id] ?? const ServicioExtras();
    return ServicioItem(
      id: s.id,
      name: s.nombre,
      description: s.descripcion,
      durationMinutes: s.duracionMin,
      flexibleDuration: extras.flexibleDuration,
      priceUyu: s.precio.round(),
      priceFrom: extras.priceFrom,
      active: s.activo,
      schedulingMode: extras.schedulingMode,
      professionalIds: extras.professionalIds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ── Filtering & search ────────────────────────────────────────────────────

  void setFilter(ServicioFilter filter) => state = state.copyWith(filter: filter);
  void setQuery(String query) => state = state.copyWith(query: query);

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> toggleActive(String id) async {
    final idx = state.items.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    final s = state.items[idx];
    final updated = List<ServicioItem>.from(state.items);
    updated[idx] = s.copyWith(active: !s.active);
    state = state.copyWith(items: updated);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      await api.updateService(
        businessId: _key.businessId,
        serviceId: id,
        nombre: s.name,
        descripcion: s.description,
        duracionMin: s.durationMinutes,
        precio: s.priceUyu.toDouble(),
        activo: !s.active,
      );
    } catch (_) {
      final reverted = List<ServicioItem>.from(state.items);
      reverted[idx] = s;
      state = state.copyWith(items: reverted);
    }
  }

  Future<void> createService({
    required String nombre,
    String? descripcion,
    required int duracionMin,
    required int precio,
    required ServicioExtras extras,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final created = await api.createService(
      businessId: _key.businessId,
      nombre: nombre,
      descripcion: descripcion,
      duracionMin: duracionMin,
      precio: precio.toDouble(),
      schedulingMode: extras.schedulingMode.toApi(),
      staffMemberIds: extras.schedulingMode == ServiceSchedulingMode.byStaff
          ? extras.professionalIds
          : const [],
    );
    _extras[created.id] = extras;
    await _load();
  }

  Future<void> updateService({
    required String id,
    required String nombre,
    String? descripcion,
    required int duracionMin,
    required int precio,
    required bool activo,
    required ServicioExtras extras,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    await api.updateService(
      businessId: _key.businessId,
      serviceId: id,
      nombre: nombre,
      descripcion: descripcion,
      duracionMin: duracionMin,
      precio: precio.toDouble(),
      activo: activo,
      schedulingMode: extras.schedulingMode.toApi(),
      staffMemberIds: extras.schedulingMode == ServiceSchedulingMode.byStaff
          ? extras.professionalIds
          : const [],
    );

    _extras[id] = extras;
    await _load();
  }

  Future<void> remove(String id) async {
    final api = _ref.read(agendaApiServiceProvider);
    await api.deleteService(businessId: _key.businessId, serviceId: id);
    _extras.remove(id);
    state = state.copyWith(items: state.items.where((s) => s.id != id).toList());
  }

  Future<void> changeCategory(BusinessCategory category) =>
      setCategories([category]);

  Future<void> setCategories(List<BusinessCategory> categories) async {
    final newList = categories.isEmpty
        ? const [BusinessCategory.otra]
        : categories;

    // Optimistic UI update — el listener de businessesProvider reconcilia tras el reload.
    state = state.copyWith(categories: newList);

    try {
      final all = await _ref.read(publicCategoriesProvider.future);
      final ids = <String>[];
      for (final c in newList) {
        if (c == BusinessCategory.otra) continue; // sin equivalente en backend
        final match = all.where((cat) => cat.slug == c.slug).firstOrNull;
        if (match != null) ids.add(match.id);
      }

      await _ref
          .read(businessesProvider(_key.tenantId).notifier)
          .associateCategories(
            businessId: _key.businessId,
            categoryIds: ids,
          );
    } catch (e) {
      state = state.copyWith(
        error: 'No se pudieron guardar las categorías: $e',
      );
    }
  }

  void duplicate(ServicioItem s) async {
    final extras = _extras[s.id] ?? const ServicioExtras();
    final api = _ref.read(agendaApiServiceProvider);
    final created = await api.createService(
      businessId: _key.businessId,
      nombre: '${s.name} (copia)',
      descripcion: s.description,
      duracionMin: s.durationMinutes,
      precio: s.priceUyu.toDouble(),
    );
    _extras[created.id] = extras;
    state = state.copyWith(items: [...state.items, _toItem(created)]);
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  List<ServicioItem> get visibleItems {
    var filtered = state.items;
    switch (state.filter) {
      case ServicioFilter.active:
        filtered = filtered.where((s) => s.active).toList();
      case ServicioFilter.inactive:
        filtered = filtered.where((s) => !s.active).toList();
      case ServicioFilter.all:
        break;
    }

    final q = state.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((s) {
        if (s.name.toLowerCase().contains(q)) return true;
        if (s.description?.toLowerCase().contains(q) == true) return true;
        return false;
      }).toList();
    }

    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  List<StaffMember> staffForService(ServicioItem s) {
    final ids = s.professionalIds.toSet();
    return state.staff.where((m) => ids.contains(m.id)).toList();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final serviciosProvider = StateNotifierProvider.autoDispose
    .family<ServiciosNotifier, ServiciosState, ServiciosKey>(
  (ref, key) => ServiciosNotifier(ref, key),
);

// ─── Stats (placeholder — no backend endpoint yet) ────────────────────────────

ServiceStats statsFor(String serviceId) => ServiceStats.zero;
