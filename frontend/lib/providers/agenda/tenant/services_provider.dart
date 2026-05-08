import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class ServicesState {
  final List<AgendaService> items;
  final bool isLoading;
  final String? error;

  const ServicesState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  ServicesState copyWith({
    List<AgendaService>? items,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return ServicesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

typedef _ServiceKey = ({String tenantId, String businessId});

class ServicesNotifier extends StateNotifier<ServicesState> {
  ServicesNotifier(this._ref, this._key)
      : super(const ServicesState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final _ServiceKey _key;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final items = await api.listTenantServices(
        businessId: _key.businessId,
      );
      state = ServicesState(items: items);
    } on AgendaApiException catch (e) {
      state = ServicesState(error: e.message);
    }
  }

  Future<AgendaService> create({
    required String nombre,
    String? descripcion,
    required int duracionMin,
    required double precio,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final created = await api.createService(
      businessId: _key.businessId,
      nombre: nombre,
      descripcion: descripcion,
      duracionMin: duracionMin,
      precio: precio,
    );
    state = state.copyWith(items: [...state.items, created]);
    return created;
  }

  Future<AgendaService> update({
    required String serviceId,
    required String nombre,
    String? descripcion,
    required int duracionMin,
    required double precio,
    required bool activo,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final updated = await api.updateService(
      businessId: _key.businessId,
      serviceId: serviceId,
      nombre: nombre,
      descripcion: descripcion,
      duracionMin: duracionMin,
      precio: precio,
      activo: activo,
    );
    state = state.copyWith(
      items: [
        for (final s in state.items)
          if (s.id == serviceId) updated else s,
      ],
    );
    return updated;
  }

  Future<void> delete(String serviceId) async {
    final api = _ref.read(agendaApiServiceProvider);
    await api.deleteService(
      businessId: _key.businessId,
      serviceId: serviceId,
    );
    state = state.copyWith(
      items: state.items.where((s) => s.id != serviceId).toList(),
    );
  }
}

final servicesProvider = StateNotifierProvider.autoDispose
    .family<ServicesNotifier, ServicesState, _ServiceKey>((ref, key) {
  return ServicesNotifier(ref, key);
});
