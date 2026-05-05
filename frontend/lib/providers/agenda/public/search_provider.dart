import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/business_summary.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

/// Estado del buscador público.
class SearchState {
  final String query;
  final String tenantId;
  final String? categorySlug;
  final List<BusinessSummary> results;
  final bool isLoading;
  final String? error;
  final bool hasSearched;

  const SearchState({
    this.query = '',
    this.tenantId = '',
    this.categorySlug,
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
  });

  SearchState copyWith({
    String? query,
    String? tenantId,
    Object? categorySlug = _sentinel,
    List<BusinessSummary>? results,
    bool? isLoading,
    Object? error = _sentinel,
    bool? hasSearched,
  }) {
    return SearchState(
      query: query ?? this.query,
      tenantId: tenantId ?? this.tenantId,
      categorySlug: identical(categorySlug, _sentinel)
          ? this.categorySlug
          : categorySlug as String?,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }

  static const _sentinel = Object();
}

/// Notifier que ejecuta la búsqueda con debounce de 300 ms.
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._ref) : super(const SearchState()) {
    _loadAll();
  }

  final Ref _ref;
  Timer? _debounce;

  void setTenantId(String tenantId) {
    state = state.copyWith(tenantId: tenantId);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), _fetch);
  }

  void onQueryChanged(String q) {
    state = state.copyWith(query: q);
    _debounce?.cancel();
    _debounce = Timer(
      q.trim().isEmpty ? const Duration(milliseconds: 50) : const Duration(milliseconds: 300),
      _fetch,
    );
  }

  void setCategorySlug(String? slug) {
    state = state.copyWith(categorySlug: slug);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), _fetch);
  }

  Future<void> _loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final tenantId = state.tenantId.trim();
      final results = await api.search(
        q: '',
        tenantId: tenantId.isEmpty ? null : tenantId,
        categorySlug: state.categorySlug,
      );
      state = state.copyWith(results: results, isLoading: false, hasSearched: true);
    } on AgendaApiException catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.message, hasSearched: true, results: const []);
    }
  }

  Future<void> _fetch() async {
    final q = state.query.trim();
    final tenantId = state.tenantId.trim();
    final slug = state.categorySlug;

    // Sin query ni categoría → cargamos todo
    if (q.isEmpty && slug == null) {
      return _loadAll();
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      List<BusinessSummary> results;

      if (slug != null) {
        // El backend tiene endpoint dedicado para filtrar por categoría
        results = await api.businessesByCategory(
          slug: slug,
          tenantId: tenantId.isEmpty ? null : tenantId,
        );
        // Si además hay query, filtramos client-side sobre los resultados
        if (q.isNotEmpty) {
          final lq = q.toLowerCase();
          results = results
              .where((b) =>
                  b.nombre.toLowerCase().contains(lq) ||
                  (b.descripcion?.toLowerCase().contains(lq) ?? false) ||
                  b.categorias.any((c) => c.toLowerCase().contains(lq)))
              .toList();
        }
      } else {
        results = await api.search(
          q: q,
          tenantId: tenantId.isEmpty ? null : tenantId,
        );
      }

      state = state.copyWith(results: results, isLoading: false, hasSearched: true);
    } on AgendaApiException catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.message, hasSearched: true, results: const []);
    }
  }

  Future<void> retry() => _fetch();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref);
});
