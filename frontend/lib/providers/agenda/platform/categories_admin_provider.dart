import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/category.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class CategoriesAdminState {
  final List<Category> items;
  final bool isLoading;
  final String? error;

  const CategoriesAdminState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  CategoriesAdminState copyWith({
    List<Category>? items,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return CategoriesAdminState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class CategoriesAdminNotifier extends StateNotifier<CategoriesAdminState> {
  CategoriesAdminNotifier(this._ref) : super(const CategoriesAdminState()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final items = await api.listAllCategories();
      state = state.copyWith(items: items, isLoading: false);
    } on AgendaApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<Category> create({
    required String nombre,
    required String slug,
    required List<String> synonyms,
    bool activo = true,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final created = await api.createCategory(
      nombre: nombre,
      slug: slug,
      synonyms: synonyms,
      activo: activo,
    );
    state = state.copyWith(items: [...state.items, created]);
    return created;
  }

  Future<Category> update({
    required String id,
    required String nombre,
    required String slug,
    required List<String> synonyms,
    required bool activo,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final updated = await api.updateCategory(
      id: id,
      nombre: nombre,
      slug: slug,
      synonyms: synonyms,
      activo: activo,
    );
    state = state.copyWith(
      items: [
        for (final c in state.items)
          if (c.id == id) updated else c,
      ],
    );
    return updated;
  }

  Future<void> delete(String id) async {
    final api = _ref.read(agendaApiServiceProvider);
    await api.deleteCategory(id);
    state = state.copyWith(items: state.items.where((c) => c.id != id).toList());
  }
}

final categoriesAdminProvider = StateNotifierProvider.autoDispose<
    CategoriesAdminNotifier, CategoriesAdminState>((ref) {
  return CategoriesAdminNotifier(ref);
});
