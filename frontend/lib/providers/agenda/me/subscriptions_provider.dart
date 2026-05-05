import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/subscription.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class SubscriptionsState {
  final List<Subscription> items;
  final bool isLoading;
  final String? error;
  final bool onlyActive;

  const SubscriptionsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.onlyActive = false,
  });

  SubscriptionsState copyWith({
    List<Subscription>? items,
    bool? isLoading,
    Object? error = _sentinel,
    bool? onlyActive,
  }) {
    return SubscriptionsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      onlyActive: onlyActive ?? this.onlyActive,
    );
  }

  static const _sentinel = Object();
}

class SubscriptionsNotifier extends StateNotifier<SubscriptionsState> {
  SubscriptionsNotifier(this._ref) : super(const SubscriptionsState(isLoading: true)) {
    load();
  }

  final Ref _ref;

  Future<void> load({bool? onlyActive}) async {
    final active = onlyActive ?? state.onlyActive;
    state = state.copyWith(isLoading: true, error: null, onlyActive: active);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final items = await api.mySubscriptions(onlyActive: active);
      state = SubscriptionsState(items: items, onlyActive: active);
    } on AgendaApiException catch (e) {
      state = SubscriptionsState(error: e.message, onlyActive: active);
    }
  }

  Future<Subscription> purchase({
    required String tenantId,
    required String businessId,
    required String planId,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final created = await api.purchaseSubscription(
      tenantId: tenantId,
      businessId: businessId,
      planId: planId,
    );
    state = state.copyWith(items: [...state.items, created]);
    return created;
  }
}

final subscriptionsProvider =
    StateNotifierProvider.autoDispose<SubscriptionsNotifier, SubscriptionsState>(
  (ref) => SubscriptionsNotifier(ref),
);
