import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../models/agenda/public_client.dart';
import '../../../../../providers/agenda/agenda_api_provider.dart';
import 'cliente.dart';

enum ClientesFilter { todos, vip, fiel, nuevo }

class ClientesState {
  final List<Cliente> all;
  final String query;
  final ClientesFilter filter;
  final String? selectedId;
  final bool loading;
  final String? error;

  const ClientesState({
    this.all = const [],
    this.query = '',
    this.filter = ClientesFilter.todos,
    this.selectedId,
    this.loading = false,
    this.error,
  });

  ClientesState copyWith({
    List<Cliente>? all,
    String? query,
    ClientesFilter? filter,
    Object? selectedId = _sentinel,
    bool? loading,
    Object? error = _sentinel,
  }) {
    return ClientesState(
      all: all ?? this.all,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      selectedId:
          identical(selectedId, _sentinel) ? this.selectedId : selectedId as String?,
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class ClientesNotifier extends StateNotifier<ClientesState> {
  ClientesNotifier({
    required this.ref,
    required this.businessId,
    DateTime? now,
  })  : _now = now ?? DateTime.now(),
        super(const ClientesState(loading: true));

  final Ref ref;
  final String businessId;
  final DateTime _now;

  DateTime get now => _now;

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final api = ref.read(agendaApiServiceProvider);
      final results = await api.tenantSearchClients(businessId: businessId, q: '');
      final clientes = results.map(_fromPublic).toList();
      if (!mounted) return;
      state = state.copyWith(all: clientes, loading: false, error: null);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Cliente _fromPublic(PublicClient c) => Cliente(
        id: c.id,
        nombre: c.nombre,
        telefono: c.telefono ?? '',
        clienteDesde: c.clienteDesde ?? _now,
        visitas: c.visitas,
        inasistencias: c.inasistencias,
        gastoAcumulado: c.gastoAcumulado,
        ultimaVisita: c.ultimaVisita,
      );

  // ── Mutations ───────────────────────────────────────────────────────────────

  void setQuery(String q) => state = state.copyWith(query: q);
  void setFilter(ClientesFilter f) => state = state.copyWith(filter: f);
  void select(String id) => state = state.copyWith(selectedId: id);

  /// Crea un cliente vía `POST /me/businesses/{businessId}/clients` y lo
  /// agrega al estado local sin re-fetchear toda la lista.
  Future<Cliente?> create({
    required String nombre,
    required String telefono,
    String? email,
  }) async {
    try {
      final api = ref.read(agendaApiServiceProvider);
      final created = await api.tenantCreateClient(
        businessId: businessId,
        nombre: nombre,
        telefono: telefono,
        email: email,
      );
      final cliente = _fromPublic(created);
      if (!mounted) return cliente;
      state = state.copyWith(
        all: [cliente, ...state.all],
        selectedId: cliente.id,
        error: null,
      );
      return cliente;
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // ── Computed ────────────────────────────────────────────────────────────────

  double get _vipThreshold => _vipSpendThreshold(state.all);

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

// El umbral VIP por gasto (top 10% del negocio) se calcula sobre el snapshot
// actual del provider.
double _vipSpendThreshold(List<Cliente> all) {
  if (all.isEmpty) return double.infinity;
  final sorted = all.map((c) => c.gastoAcumulado).toList()..sort();
  final idx = ((sorted.length - 1) * 0.9).round();
  return sorted[idx];
}

final clientesProvider = StateNotifierProvider.autoDispose
    .family<ClientesNotifier, ClientesState, String>(
  (ref, businessId) {
    final notifier = ClientesNotifier(ref: ref, businessId: businessId);
    notifier.load();
    return notifier;
  },
);
