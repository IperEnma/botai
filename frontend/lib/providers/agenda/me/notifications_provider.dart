import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/agenda_notification.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class NotificationsState {
  final List<AgendaNotification> items;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<AgendaNotification>? items,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._ref)
      : super(const NotificationsState(isLoading: true)) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final items = await api.myNotifications();
      state = NotificationsState(items: items);
    } on AgendaApiException catch (e) {
      state = NotificationsState(error: e.message);
    }
  }

  /// Marca como leída visualmente (sin backend por ahora).
  void markAsRead(String id) {
    state = state.copyWith(
      items: state.items
          .map((n) => n.id == id
              ? n.copyWith(estado: NotificationEstado.leida)
              : n)
          .toList(),
    );
  }
}

final notificationsProvider =
    StateNotifierProvider.autoDispose<NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(ref),
);
