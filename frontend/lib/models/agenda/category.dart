import 'agenda_json.dart';

/// Categoría del catálogo global de AGENDA. Espejo de `CategoryResponse` del backend.
class Category {
  final String id;
  final String nombre;
  final String slug;
  final List<String> synonyms;
  final bool activo;

  const Category({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.synonyms,
    required this.activo,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: AgendaJson.parseString(json['id']),
      nombre: AgendaJson.parseString(json['nombre']),
      slug: AgendaJson.parseString(json['slug']),
      synonyms: AgendaJson.parseStringList(json['synonyms']),
      activo: AgendaJson.parseBool(json['activo'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'slug': slug,
        'synonyms': synonyms,
        'activo': activo,
      };

  Category copyWith({
    String? id,
    String? nombre,
    String? slug,
    List<String>? synonyms,
    bool? activo,
  }) {
    return Category(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      slug: slug ?? this.slug,
      synonyms: synonyms ?? this.synonyms,
      activo: activo ?? this.activo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
