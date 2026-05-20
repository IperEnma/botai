import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../services/agenda_api_exception.dart';
import '../data/service_group_catalog.dart';
import '../models/business_category.dart';
import '../models/service_group.dart';
import '../models/service_stats.dart';
import '../models/servicio_item.dart';

// ─── Key ──────────────────────────────────────────────────────────────────────

typedef ServiciosKey = ({String tenantId, String businessId});

// ─── Filter enum ──────────────────────────────────────────────────────────────

enum ServicioFilter { all, active, inactive }

// ─── UI-only extras (not in backend model yet) ────────────────────────────────

class ServicioExtras {
  final String groupId;
  final bool flexibleDuration;
  final bool priceFrom;
  final List<String> professionalIds;

  const ServicioExtras({
    this.groupId = 'otros',
    this.flexibleDuration = false,
    this.priceFrom = false,
    this.professionalIds = const [],
  });

  ServicioExtras copyWith({
    String? groupId,
    bool? flexibleDuration,
    bool? priceFrom,
    List<String>? professionalIds,
  }) =>
      ServicioExtras(
        groupId: groupId ?? this.groupId,
        flexibleDuration: flexibleDuration ?? this.flexibleDuration,
        priceFrom: priceFrom ?? this.priceFrom,
        professionalIds: professionalIds ?? this.professionalIds,
      );
}

// ─── State ────────────────────────────────────────────────────────────────────

class ServiciosState {
  final List<ServicioItem> items;
  final List<StaffMember> staff;
  final ServicioFilter filter;
  final String query;
  final BusinessCategory category;
  final List<ServiceGroup> extraGroups;
  final bool isLoading;
  final String? error;

  const ServiciosState({
    this.items = const [],
    this.staff = const [],
    this.filter = ServicioFilter.all,
    this.query = '',
    this.category = BusinessCategory.otra,
    this.extraGroups = const [],
    this.isLoading = false,
    this.error,
  });

  ServiciosState copyWith({
    List<ServicioItem>? items,
    List<StaffMember>? staff,
    ServicioFilter? filter,
    String? query,
    BusinessCategory? category,
    List<ServiceGroup>? extraGroups,
    bool? isLoading,
    Object? error = _sentinel,
  }) =>
      ServiciosState(
        items: items ?? this.items,
        staff: staff ?? this.staff,
        filter: filter ?? this.filter,
        query: query ?? this.query,
        category: category ?? this.category,
        extraGroups: extraGroups ?? this.extraGroups,
        isLoading: isLoading ?? this.isLoading,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );

  static const _sentinel = Object();

  int get countActive => items.where((s) => s.active).length;
  int get countInactive => items.where((s) => !s.active).length;
  int get totalBookingsThisMonth => 0; // no stats endpoint yet
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ServiciosNotifier extends StateNotifier<ServiciosState> {
  ServiciosNotifier(this._ref, this._key)
      : super(const ServiciosState(isLoading: true)) {
    _load();
  }

  final Ref _ref;
  final ServiciosKey _key;

  // Extras stored in memory (groupId, flexibleDuration, priceFrom, professionalIds)
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
      groupId: extras.groupId,
      durationMinutes: s.duracionMin,
      flexibleDuration: extras.flexibleDuration,
      priceUyu: s.precio.round(),
      priceFrom: extras.priceFrom,
      active: s.activo,
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
      // Revert on failure
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
    );
    _extras[created.id] = extras;
    state = state.copyWith(items: [...state.items, _toItem(created)]);
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
    final updated = await api.updateService(
      businessId: _key.businessId,
      serviceId: id,
      nombre: nombre,
      descripcion: descripcion,
      duracionMin: duracionMin,
      precio: precio.toDouble(),
      activo: activo,
    );
    _extras[id] = extras;
    state = state.copyWith(
      items: [
        for (final s in state.items)
          if (s.id == id) _toItem(updated) else s,
      ],
    );
  }

  Future<void> remove(String id) async {
    final api = _ref.read(agendaApiServiceProvider);
    await api.deleteService(businessId: _key.businessId, serviceId: id);
    _extras.remove(id);
    state = state.copyWith(items: state.items.where((s) => s.id != id).toList());
  }

  void moveToGroup(String id, String groupId) {
    final extras = _extras[id] ?? const ServicioExtras();
    _extras[id] = extras.copyWith(groupId: groupId);
    final idx = state.items.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    final updated = List<ServicioItem>.from(state.items);
    updated[idx] = updated[idx].copyWith(groupId: groupId);
    state = state.copyWith(items: updated);
  }

  void changeCategory(BusinessCategory category) =>
      state = state.copyWith(category: category);

  void addCustomGroup(String name) {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final group = ServiceGroup(
      id: id,
      name: name,
      parentCategory: state.category,
      order: 100 + state.extraGroups.length,
    );
    state = state.copyWith(extraGroups: [...state.extraGroups, group]);
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

  List<({ServiceGroup group, List<ServicioItem> services})> get visibleGrouped {
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

    final grouped = <String, List<ServicioItem>>{};
    for (final item in filtered) {
      grouped.putIfAbsent(item.groupId, () => []).add(item);
    }

    final catalogGroups = ServiceGroupCatalog.forCategory(state.category);
    final allGroups = [...catalogGroups, ...state.extraGroups];

    for (final list in grouped.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    final result = <({ServiceGroup group, List<ServicioItem> services})>[];
    for (final group in allGroups..sort((a, b) => a.order.compareTo(b.order))) {
      final services = grouped[group.id] ?? [];
      if (services.isNotEmpty) {
        result.add((group: group, services: services));
      }
    }

    // Orphan groups — services whose groupId isn't in any known group
    final knownGroupIds = allGroups.map((g) => g.id).toSet();
    for (final gid in grouped.keys.where((id) => !knownGroupIds.contains(id))) {
      final services = grouped[gid]!;
      if (services.isNotEmpty) {
        result.add((
          group: ServiceGroup(
            id: gid,
            name: gid == 'otros' ? 'Otros' : gid,
            parentCategory: state.category,
            order: 999,
          ),
          services: services,
        ));
      }
    }

    return result;
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
