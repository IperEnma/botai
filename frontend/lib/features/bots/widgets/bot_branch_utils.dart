import '../../../models/agenda/business.dart';

/// Nombres de sucursales Agenda vinculadas a un bot (`agenda_businesses.bot_id`).
List<String> branchNamesForBot(List<Business> businesses, String botId) {
  final id = int.tryParse(botId);
  if (id == null) return const [];
  return businesses
      .where((b) => b.botId == id)
      .map((b) => b.nombre)
      .where((n) => n.isNotEmpty)
      .toList();
}

String formatBranchSummary(List<String> names) {
  if (names.isEmpty) return 'Sin sucursal vinculada';
  if (names.length == 1) return names.first;
  if (names.length <= 2) return names.join(' · ');
  return '${names.first} +${names.length - 1} más';
}
