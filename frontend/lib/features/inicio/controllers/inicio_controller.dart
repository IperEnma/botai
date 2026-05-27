import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repo.dart';
import '../models/dashboard_snapshot.dart';

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
  final DashboardRepo _repo;

  InicioController(this._repo) : super(const InicioState()) {
    refresh();
  }

  void selectBranch(String id) {
    final newId = state.selectedBranchId == id ? 'all' : id;
    state = state.copyWith(selectedBranchId: newId);
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final snapshot = _repo.getMockSnapshot();
      state = state.copyWith(snapshot: snapshot, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final _dashboardRepoProvider = Provider<DashboardRepo>((ref) {
  return DashboardRepo();
});

final inicioControllerProvider =
    StateNotifierProvider<InicioController, InicioState>((ref) {
  final repo = ref.watch(_dashboardRepoProvider);
  return InicioController(repo);
});
