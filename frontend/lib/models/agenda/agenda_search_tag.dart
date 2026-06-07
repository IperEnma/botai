import 'agenda_json.dart';

/// Etiqueta de búsqueda/perfil con tipo explícito (`profile`, `location`, …).
class AgendaSearchTag {
  final String value;
  final String type;

  const AgendaSearchTag({
    required this.value,
    this.type = AgendaSearchTagType.profile,
  });

  factory AgendaSearchTag.profile(String value) =>
      AgendaSearchTag(value: value.trim(), type: AgendaSearchTagType.profile);

  factory AgendaSearchTag.location(String value) =>
      AgendaSearchTag(value: value.trim(), type: AgendaSearchTagType.location);

  factory AgendaSearchTag.fromJson(Map<String, dynamic> json) {
    return AgendaSearchTag(
      value: AgendaJson.parseString(json['value']),
      type: AgendaJson.parseString(json['type'],
          fallback: AgendaSearchTagType.profile),
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'type': type,
      };

  bool get isProfile => type == AgendaSearchTagType.profile;
  bool get isLocation => type == AgendaSearchTagType.location;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgendaSearchTag && other.value == value && other.type == type);

  @override
  int get hashCode => Object.hash(value, type);
}

abstract final class AgendaSearchTagType {
  static const profile = 'profile';
  static const location = 'location';
}

/// Combina etiquetas de ubicación existentes con nuevas de perfil.
List<AgendaSearchTag> mergeAgendaSearchTags({
  required List<AgendaSearchTag> existing,
  required List<String> profileLabels,
}) {
  final location =
      existing.where((t) => t.isLocation).toList(growable: false);
  final profile = profileLabels
      .map((label) => label.trim())
      .where((label) => label.isNotEmpty)
      .map(AgendaSearchTag.profile)
      .toList(growable: false);
  return [...location, ...profile];
}
