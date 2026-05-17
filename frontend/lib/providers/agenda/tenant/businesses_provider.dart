import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/business.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class BusinessesState {
  final List<Business> items;
  final bool isLoading;
  final String? error;

  const BusinessesState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  BusinessesState copyWith({
    List<Business>? items,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return BusinessesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class BusinessesNotifier extends StateNotifier<BusinessesState> {
  BusinessesNotifier(this._ref, this._tenantId)
      : super(const BusinessesState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final String _tenantId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final items = await api.listBusinesses(_tenantId);
      state = BusinessesState(items: items);
    } on AgendaApiException catch (e) {
      state = BusinessesState(error: e.message);
    }
  }

  Future<Business> create({
    required String nombre,
    String? descripcion,
    List<String> searchTags = const [],
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final created = await api.createBusiness(
      nombre: nombre,
      descripcion: descripcion,
      searchTags: searchTags,
    );
    state = state.copyWith(items: [...state.items, created]);
    return created;
  }

  Future<Business> update({
    required String businessId,
    required String nombre,
    String? descripcion,
    List<String> searchTags = const [],
    String? logoUrl,
    String? colorPrimario,
    String? instagramUrl,
    String? tiktokUrl,
    String? facebookUrl,
    String? colorFondo,
    String? fontFamily,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final updated = await api.updateBusiness(
      businessId: businessId,
      nombre: nombre,
      descripcion: descripcion,
      searchTags: searchTags,
      logoUrl: logoUrl,
      colorPrimario: colorPrimario,
      instagramUrl: instagramUrl,
      tiktokUrl: tiktokUrl,
      facebookUrl: facebookUrl,
      colorFondo: colorFondo,
      fontFamily: fontFamily,
    );
    state = state.copyWith(
      items: [
        for (final b in state.items)
          if (b.id == businessId) updated else b,
      ],
    );
    return updated;
  }

  Future<void> associateCategories({
    required String businessId,
    required List<String> categoryIds,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    await api.associateCategories(
      businessId: businessId,
      categoryIds: categoryIds,
    );
    // Reload to get updated categorias list from backend
    await load();
  }
}

final businessesProvider = StateNotifierProvider.autoDispose
    .family<BusinessesNotifier, BusinessesState, String>((ref, tenantId) {
  return BusinessesNotifier(ref, tenantId);
});
