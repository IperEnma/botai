import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/loyalty_suggestion.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class LoyaltyState {
  final List<LoyaltySuggestion> items;
  final bool isLoading;
  final String? error;

  const LoyaltyState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  LoyaltyState copyWith({
    List<LoyaltySuggestion>? items,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return LoyaltyState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

typedef _LoyaltyKey = ({String tenantId, String businessId});

class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  LoyaltyNotifier(this._ref, this._key)
      : super(const LoyaltyState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final _LoyaltyKey _key;

  Future<void> load({LoyaltySuggestionEstado? estado}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final items = await api.listLoyaltySuggestions(
        businessId: _key.businessId,
        estado: estado,
      );
      state = LoyaltyState(items: items);
    } on AgendaApiException catch (e) {
      state = LoyaltyState(error: e.message);
    }
  }

  Future<void> patch(String id, LoyaltySuggestionEstado estado) async {
    final api = _ref.read(agendaApiServiceProvider);
    final updated = await api.patchLoyaltySuggestion(
      businessId: _key.businessId,
      id: id,
      estado: estado,
    );
    state = state.copyWith(
      items: [for (final s in state.items) if (s.id == id) updated else s],
    );
  }

  Future<void> send(String id) async {
    final api = _ref.read(agendaApiServiceProvider);
    final updated = await api.sendLoyaltySuggestion(
      businessId: _key.businessId,
      id: id,
    );
    state = state.copyWith(
      items: [for (final s in state.items) if (s.id == id) updated else s],
    );
  }
}

final loyaltyProvider = StateNotifierProvider.autoDispose
    .family<LoyaltyNotifier, LoyaltyState, _LoyaltyKey>((ref, key) {
  return LoyaltyNotifier(ref, key);
});
