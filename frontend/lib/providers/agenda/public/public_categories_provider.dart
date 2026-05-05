import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/business_summary.dart';
import '../../../models/agenda/category.dart';
import '../agenda_api_provider.dart';

/// Catálogo global de categorías para chips/filtros del buscador público.
final publicCategoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  final api = ref.watch(agendaApiServiceProvider);
  return api.listPublicCategories();
});

/// Negocios filtrados por slug de categoría (necesita tenantId).
final businessesByCategoryProvider = FutureProvider.autoDispose
    .family<List<BusinessSummary>, ({String slug, String tenantId})>((ref, args) {
  final api = ref.watch(agendaApiServiceProvider);
  return api.businessesByCategory(slug: args.slug, tenantId: args.tenantId);
});
