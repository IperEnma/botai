import 'agenda_json.dart';

/// Proyección pública de un negocio para el buscador y los listados por categoría.
/// Espejo de `BusinessSummaryResponse` del backend.
class BusinessSummary {
  final String id;
  final String tenantId;
  final String nombre;
  final String? descripcion;
  final List<String> categorias;
  final bool activo;
  final String? logoUrl;
  final String? localidad;
  final String? departamento;
  final String? pais;
  final String? publicSlug;

  const BusinessSummary({
    required this.id,
    required this.tenantId,
    required this.nombre,
    this.descripcion,
    required this.categorias,
    required this.activo,
    this.logoUrl,
    this.localidad,
    this.departamento,
    this.pais,
    this.publicSlug,
  });

  /// Ruta pública única del perfil: `/reservar/{publicSlug}`.
  String? get profilePath {
    final s = publicSlug;
    if (s == null || s.isEmpty) return null;
    return '/reservar/$s';
  }

  String? get direccionCorta {
    final parts = [localidad, departamento].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  factory BusinessSummary.fromJson(Map<String, dynamic> json) {
    return BusinessSummary(
      id: AgendaJson.parseString(json['id']),
      tenantId: AgendaJson.parseString(json['tenantId']),
      nombre: AgendaJson.parseString(json['nombre']),
      descripcion: AgendaJson.parseStringOrNull(json['descripcion']),
      categorias: AgendaJson.parseStringList(json['categorias']),
      activo: AgendaJson.parseBool(json['activo'], fallback: true),
      logoUrl: AgendaJson.parseStringOrNull(json['logoUrl']),
      localidad: AgendaJson.parseStringOrNull(json['localidad']),
      departamento: AgendaJson.parseStringOrNull(json['departamento']),
      pais: AgendaJson.parseStringOrNull(json['pais']),
      publicSlug: AgendaJson.parseStringOrNull(json['publicSlug']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessSummary && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
