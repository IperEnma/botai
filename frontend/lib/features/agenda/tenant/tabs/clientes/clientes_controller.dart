import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cliente.dart';

enum ClientesFilter { todos, vip, fiel, nuevo }

class ClientesState {
  final List<Cliente> all;
  final String query;
  final ClientesFilter filter;
  final String? selectedId;

  const ClientesState({
    this.all = const [],
    this.query = '',
    this.filter = ClientesFilter.todos,
    this.selectedId,
  });

  ClientesState copyWith({
    List<Cliente>? all,
    String? query,
    ClientesFilter? filter,
    Object? selectedId = _sentinel,
  }) {
    return ClientesState(
      all: all ?? this.all,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      selectedId:
          identical(selectedId, _sentinel) ? this.selectedId : selectedId as String?,
    );
  }

  static const _sentinel = Object();
}

class ClientesNotifier extends StateNotifier<ClientesState> {
  ClientesNotifier({DateTime? now})
      : _now = now ?? DateTime.now(),
        super(const ClientesState());

  final DateTime _now;

  DateTime get now => _now;

  // ── Mutations ───────────────────────────────────────────────────────────────

  void setQuery(String q) => state = state.copyWith(query: q);
  void setFilter(ClientesFilter f) => state = state.copyWith(filter: f);
  void select(String id) => state = state.copyWith(selectedId: id);

  // ── Computed ────────────────────────────────────────────────────────────────

  late final double _vipThreshold = _vipSpendThreshold(state.all);

  ClienteTag tagOf(Cliente c) =>
      deriveTag(c, vipThreshold: _vipThreshold, now: _now);

  ClientesKpis get kpis => ClientesKpis.from(state.all, now: _now);

  /// Lista filtrada por query (nombre / teléfono) + chip de filtro.
  List<Cliente> get visible {
    final q = state.query.trim().toLowerCase();
    final filter = state.filter;
    return state.all.where((c) {
      if (q.isNotEmpty) {
        final matches = c.nombre.toLowerCase().contains(q) ||
            c.telefono.replaceAll(' ', '').contains(q.replaceAll(' ', ''));
        if (!matches) return false;
      }
      if (filter == ClientesFilter.todos) return true;
      final tag = tagOf(c);
      return switch (filter) {
        ClientesFilter.vip => tag == ClienteTag.vip,
        ClientesFilter.fiel => tag == ClienteTag.fiel,
        ClientesFilter.nuevo => tag == ClienteTag.nuevo,
        ClientesFilter.todos => true,
      };
    }).toList();
  }

  Cliente? get selected {
    final id = state.selectedId;
    if (id == null) return null;
    return state.all.where((c) => c.id == id).firstOrNull;
  }
}

// El umbral VIP por gasto (top 10% del negocio) se calcula una vez al cargar.
double _vipSpendThreshold(List<Cliente> all) {
  if (all.isEmpty) return double.infinity;
  final sorted = all.map((c) => c.gastoAcumulado).toList()..sort();
  final idx = ((sorted.length - 1) * 0.9).round();
  return sorted[idx];
}

final clientesProvider =
    StateNotifierProvider.autoDispose<ClientesNotifier, ClientesState>(
  (ref) => ClientesNotifier(),
);
