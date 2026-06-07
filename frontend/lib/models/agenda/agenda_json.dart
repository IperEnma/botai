/// Helpers de parseo defensivo para los modelos del módulo AGENDA.
///
/// Replica el patrón usado en `Bot.fromJson` del bot: tolerar nulls,
/// formatos numéricos, strings con padding y listas que vienen como
/// `List<dynamic>` desde JSON.
import 'agenda_search_tag.dart';

class AgendaJson {
  AgendaJson._();

  static String parseString(dynamic value, {String fallback = ''}) {
    if (value == null) { return fallback; }
    return value.toString();
  }

  static String? parseStringOrNull(dynamic value) {
    if (value == null) { return null; }
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  static bool parseBool(dynamic value, {bool fallback = false}) {
    if (value == null) { return fallback; }
    if (value is bool) { return value; }
    if (value is num) { return value != 0; }
    final s = value.toString().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  static int parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) { return fallback; }
    if (value is int) { return value; }
    if (value is num) { return value.toInt(); }
    return int.tryParse(value.toString()) ?? fallback;
  }

  static int? parseIntOrNull(dynamic value) {
    if (value == null) { return null; }
    if (value is int) { return value; }
    if (value is num) { return value.toInt(); }
    return int.tryParse(value.toString());
  }

  static double parseDouble(dynamic value, {double fallback = 0}) {
    if (value == null) { return fallback; }
    if (value is double) { return value; }
    if (value is num) { return value.toDouble(); }
    return double.tryParse(value.toString()) ?? fallback;
  }

  static double? parseDoubleOrNull(dynamic value) {
    if (value == null) { return null; }
    if (value is double) { return value; }
    if (value is num) { return value.toDouble(); }
    return double.tryParse(value.toString());
  }

  static List<String> parseStringList(dynamic value) {
    if (value == null) { return const []; }
    if (value is List) {
      return value.map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }

  static List<AgendaSearchTag> parseSearchTagList(dynamic value) {
    if (value == null) { return const []; }
    if (value is! List) { return const []; }
    final tags = <AgendaSearchTag>[];
    for (final entry in value) {
      if (entry is Map) {
        tags.add(AgendaSearchTag.fromJson(Map<String, dynamic>.from(entry)));
      }
    }
    return tags;
  }

  static DateTime parseDateTime(dynamic value) {
    if (value == null) { return DateTime.fromMillisecondsSinceEpoch(0); }
    if (value is DateTime) { return value; }
    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? parseDateTimeOrNull(dynamic value) {
    if (value == null) { return null; }
    if (value is DateTime) { return value; }
    return DateTime.tryParse(value.toString());
  }

  /// Parsea un enum case-insensitive contra los `name` del enum.
  /// Devuelve [fallback] si no matchea (o lanza si [fallback] es null).
  static T parseEnum<T extends Enum>(
    dynamic value,
    List<T> values, {
    required T fallback,
  }) {
    if (value == null) { return fallback; }
    final s = value.toString().toUpperCase();
    for (final v in values) {
      if (v.name.toUpperCase() == s) { return v; }
    }
    return fallback;
  }
}
