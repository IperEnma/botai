import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/notification_template.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class TemplatesState {
  final List<NotificationTemplate> items;
  final bool isLoading;
  final String? error;

  const TemplatesState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  TemplatesState copyWith({
    List<NotificationTemplate>? items,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return TemplatesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

typedef _TemplatesKey = ({String tenantId, String businessId});

class TemplatesNotifier extends StateNotifier<TemplatesState> {
  TemplatesNotifier(this._ref, this._key)
      : super(const TemplatesState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final _TemplatesKey _key;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final items = await api.listTemplates(
        tenantId: _key.tenantId,
        businessId: _key.businessId,
      );
      state = TemplatesState(items: items);
    } on AgendaApiException catch (e) {
      state = TemplatesState(error: e.message);
    }
  }

  Future<NotificationTemplate> create({
    required String codigo,
    required NotificationCanal canal,
    required String titulo,
    required String cuerpo,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final created = await api.createTemplate(
      tenantId: _key.tenantId,
      businessId: _key.businessId,
      codigo: codigo,
      canal: canal,
      titulo: titulo,
      cuerpo: cuerpo,
    );
    state = state.copyWith(items: [...state.items, created]);
    return created;
  }

  Future<NotificationTemplate> update({
    required String id,
    required String titulo,
    required String cuerpo,
    required NotificationCanal canal,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final updated = await api.updateTemplate(
      tenantId: _key.tenantId,
      businessId: _key.businessId,
      id: id,
      titulo: titulo,
      cuerpo: cuerpo,
      canal: canal,
    );
    state = state.copyWith(
      items: [for (final t in state.items) if (t.id == id) updated else t],
    );
    return updated;
  }

  Future<void> delete(String id) async {
    final api = _ref.read(agendaApiServiceProvider);
    await api.deleteTemplate(
      tenantId: _key.tenantId,
      businessId: _key.businessId,
      id: id,
    );
    state = state.copyWith(
      items: state.items.where((t) => t.id != id).toList(),
    );
  }
}

final templatesProvider = StateNotifierProvider.autoDispose
    .family<TemplatesNotifier, TemplatesState, _TemplatesKey>((ref, key) {
  return TemplatesNotifier(ref, key);
});
