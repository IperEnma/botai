import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/tenant_features.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class FeaturesState {
  final TenantFeatures? features;
  final bool isLoading;
  final String? error;

  const FeaturesState({
    this.features,
    this.isLoading = false,
    this.error,
  });

  FeaturesState copyWith({
    TenantFeatures? features,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return FeaturesState(
      features: features ?? this.features,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class FeaturesNotifier extends StateNotifier<FeaturesState> {
  FeaturesNotifier(this._ref) : super(const FeaturesState(isLoading: true)) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final features = await api.getFeatures();
      state = FeaturesState(features: features);
    } on AgendaApiException catch (e) {
      state = FeaturesState(error: e.message);
    }
  }

  Future<void> update(TenantFeatures features) async {
    final prev = state.features;
    state = state.copyWith(features: features);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final updated = await api.updateFeatures(features);
      state = FeaturesState(features: updated);
    } on AgendaApiException catch (e) {
      state = FeaturesState(features: prev, error: e.message);
    }
  }
}

final featuresProvider =
    StateNotifierProvider.autoDispose<FeaturesNotifier, FeaturesState>((ref) {
  return FeaturesNotifier(ref);
});
