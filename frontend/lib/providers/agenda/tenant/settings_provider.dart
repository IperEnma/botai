import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/business_settings.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class SettingsState {
  final BusinessSettings? settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const SettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  SettingsState copyWith({
    BusinessSettings? settings,
    bool? isLoading,
    bool? isSaving,
    Object? error = _sentinel,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

typedef _SettingsKey = ({String tenantId, String businessId});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._ref, this._key)
      : super(const SettingsState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final _SettingsKey _key;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final settings = await api.getSettings(
        businessId: _key.businessId,
      );
      state = SettingsState(settings: settings);
    } on AgendaApiException catch (e) {
      state = SettingsState(error: e.message);
    }
  }

  Future<void> save(BusinessSettings settings) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final updated = await api.updateSettings(
        businessId: _key.businessId,
        settings: settings,
      );
      state = SettingsState(settings: updated);
    } on AgendaApiException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
    }
  }
}

final settingsProvider = StateNotifierProvider.autoDispose
    .family<SettingsNotifier, SettingsState, _SettingsKey>((ref, key) {
  return SettingsNotifier(ref, key);
});
