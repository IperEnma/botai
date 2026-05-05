import 'agenda_json.dart';

/// Servicio que vende un negocio. Renombrado a `AgendaService` para evitar
/// colisión con `models/service.dart` del bot.
class AgendaService {
  final String id;
  final String businessId;
  final String nombre;
  final String? descripcion;
  final int duracionMin;
  final double precio;
  final bool activo;

  const AgendaService({
    required this.id,
    required this.businessId,
    required this.nombre,
    this.descripcion,
    required this.duracionMin,
    required this.precio,
    required this.activo,
  });

  factory AgendaService.fromJson(Map<String, dynamic> json) {
    return AgendaService(
      id: AgendaJson.parseString(json['id']),
      businessId: AgendaJson.parseString(json['businessId']),
      nombre: AgendaJson.parseString(json['nombre']),
      descripcion: AgendaJson.parseStringOrNull(json['descripcion']),
      duracionMin: AgendaJson.parseInt(json['duracionMin']),
      precio: AgendaJson.parseDouble(json['precio']),
      activo: AgendaJson.parseBool(json['activo'], fallback: true),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgendaService && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
