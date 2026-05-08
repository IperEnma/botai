import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/business_hours.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class BusinessHoursState {
  final List<BusinessHours> hours;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const BusinessHoursState({
    this.hours = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  BusinessHoursState copyWith({
    List<BusinessHours>? hours,
    bool? isLoading,
    bool? isSaving,
    Object? error = _sentinel,
  }) =>
      BusinessHoursState(
        hours: hours ?? this.hours,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );

  static const _sentinel = Object();
}

class BusinessHoursNotifier extends StateNotifier<BusinessHoursState> {
  BusinessHoursNotifier(this._ref, this._businessId)
      : super(const BusinessHoursState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final String _businessId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final hours = await api.getBusinessHours(businessId: _businessId);
      state = state.copyWith(hours: hours, isLoading: false);
    } on AgendaApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<bool> save(List<BusinessHours> hours) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final saved = await api.saveBusinessHours(
          businessId: _businessId, hours: hours);
      state = state.copyWith(hours: saved, isSaving: false);
      return true;
    } on AgendaApiException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    }
  }
}

final businessHoursProvider = StateNotifierProvider.autoDispose
    .family<BusinessHoursNotifier, BusinessHoursState,
        ({String tenantId, String businessId})>((ref, key) {
  return BusinessHoursNotifier(ref, key.businessId);
});
