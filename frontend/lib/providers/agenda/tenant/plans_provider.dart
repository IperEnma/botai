import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/plan.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class PlansState {
  final List<Plan> items;
  final bool isLoading;
  final String? error;

  const PlansState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  PlansState copyWith({
    List<Plan>? items,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return PlansState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

typedef _PlanKey = ({String tenantId, String businessId});

class PlansNotifier extends StateNotifier<PlansState> {
  PlansNotifier(this._ref, this._key)
      : super(const PlansState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final _PlanKey _key;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final items = await api.listPlans(
        tenantId: _key.tenantId,
        businessId: _key.businessId,
      );
      state = PlansState(items: items);
    } on AgendaApiException catch (e) {
      state = PlansState(error: e.message);
    }
  }

  Future<Plan> create({
    required String nombrePlan,
    required PlanTipo tipo,
    PlanTier? tier,
    required int totalCreditos,
    required int validezDias,
    required double precio,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final created = await api.createPlan(
      tenantId: _key.tenantId,
      businessId: _key.businessId,
      nombrePlan: nombrePlan,
      tipo: tipo,
      tier: tier,
      totalCreditos: totalCreditos,
      validezDias: validezDias,
      precio: precio,
    );
    state = state.copyWith(items: [...state.items, created]);
    return created;
  }

  Future<Plan> update({
    required String planId,
    required String nombrePlan,
    required PlanTipo tipo,
    PlanTier? tier,
    required int totalCreditos,
    required int validezDias,
    required double precio,
    required bool activo,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final updated = await api.updatePlan(
      tenantId: _key.tenantId,
      businessId: _key.businessId,
      planId: planId,
      nombrePlan: nombrePlan,
      tipo: tipo,
      tier: tier,
      totalCreditos: totalCreditos,
      validezDias: validezDias,
      precio: precio,
      activo: activo,
    );
    state = state.copyWith(
      items: [
        for (final p in state.items)
          if (p.id == planId) updated else p,
      ],
    );
    return updated;
  }

  Future<void> delete(String planId) async {
    final api = _ref.read(agendaApiServiceProvider);
    await api.deletePlan(
      tenantId: _key.tenantId,
      businessId: _key.businessId,
      planId: planId,
    );
    state = state.copyWith(
      items: state.items.where((p) => p.id != planId).toList(),
    );
  }
}

final plansProvider = StateNotifierProvider.autoDispose
    .family<PlansNotifier, PlansState, _PlanKey>((ref, key) {
  return PlansNotifier(ref, key);
});
