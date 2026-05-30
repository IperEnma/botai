import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/business.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../agenda/register/konecta_tokens.dart';
import '../models/branch.dart';
import '../models/dashboard_snapshot.dart';
import '../models/kpi_models.dart';

class InicioState {
  final DashboardSnapshot? snapshot;
  final bool loading;
  final String selectedBranchId;
  final String? error;

  const InicioState({
    this.snapshot,
    this.loading = false,
    this.selectedBranchId = 'all',
    this.error,
  });

  InicioState copyWith({
    DashboardSnapshot? snapshot,
    bool? loading,
    String? selectedBranchId,
    String? error,
  }) {
    return InicioState(
      snapshot: snapshot ?? this.snapshot,
      loading: loading ?? this.loading,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      error: error,
    );
  }

  DashboardSnapshot? get filteredSnapshot {
    if (snapshot == null) return null;
    if (selectedBranchId == 'all') return snapshot;
    return snapshot!.filteredBy(selectedBranchId);
  }
}

class InicioController extends StateNotifier<InicioState> {
  InicioController(this._ref, this._tenantId)
      : super(const InicioState(loading: true)) {
    _ref.listen<BusinessesState>(
      businessesProvider(_tenantId),
      (_, next) => _onBusinesses(next),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  final String _tenantId;

  void selectBranch(String id) {
    final newId = state.selectedBranchId == id ? 'all' : id;
    state = state.copyWith(selectedBranchId: newId);
  }

  Future<void> refresh() async {
    await _ref.read(businessesProvider(_tenantId).notifier).load();
  }

  void _onBusinesses(BusinessesState businesses) {
    if (businesses.isLoading) return;
    if (businesses.error != null && state.snapshot == null) {
      state = InicioState(loading: false, error: businesses.error);
      return;
    }
    state = InicioState(
      snapshot: _buildSnapshot(businesses.items),
      loading: false,
      selectedBranchId: state.selectedBranchId,
    );
  }

  DashboardSnapshot _buildSnapshot(List<Business> businesses) {
    final branches = businesses.asMap().entries.map((e) {
      final biz = e.value;
      final i = e.key;
      return Branch(
        id: biz.id,
        name: biz.nombre,
        initials: _initials(biz.nombre),
        address: biz.descripcion ?? '',
        color: KTokens.proPalette[i % KTokens.proPalette.length],
        status: biz.activo ? BranchStatus.activa : BranchStatus.pausada,
        createdAt: biz.createdAt ?? DateTime.now(),
      );
    }).toList();

    return DashboardSnapshot(
      date: DateTime.now(),
      branches: branches,
      turnos: TurnosKpi(
        total: 0,
        capacity: 0,
        trendPct: 0.0,
        byBranch: {for (final b in branches) b.id: 0},
      ),
      revenue: const RevenueKpi(
        expectedUyu: 0,
        collectedUyu: 0,
        trendPct: 0.0,
      ),
      occupancy: OccupancyKpi(
        averagePct: 0.0,
        trendPct: 0.0,
        byBranch: {for (final b in branches) b.id: 0.0},
      ),
      bot: const BotKpi(
        turnosFromBot: 0,
        turnosTotal: 0,
        trendPct: 0.0,
      ),
      upcomingToday: const [],
      activity: const BotActivity(
        last7Days: [0, 0, 0, 0, 0, 0, 0],
        msgsThisMonth: 0,
        msgsQuota: 0,
        conversations: 0,
        turnosGenerated: 0,
        resolutionRate: 0.0,
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }
}

final inicioControllerProvider = StateNotifierProvider.autoDispose
    .family<InicioController, InicioState, String>(
  (ref, tenantId) => InicioController(ref, tenantId),
);
