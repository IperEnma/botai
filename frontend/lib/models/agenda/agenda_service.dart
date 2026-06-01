import 'agenda_json.dart';
import 'service_scheduling_mode.dart';

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
  final ServiceSchedulingMode schedulingMode;
  final List<String> staffMemberIds;

  const AgendaService({
    required this.id,
    required this.businessId,
    required this.nombre,
    this.descripcion,
    required this.duracionMin,
    required this.precio,
    required this.activo,
    this.schedulingMode = ServiceSchedulingMode.general,
    this.staffMemberIds = const [],
  });

  bool get requiresStaffSelection =>
      schedulingMode == ServiceSchedulingMode.byStaff;

  factory AgendaService.fromJson(Map<String, dynamic> json) {
    final staffRaw = json['staffMemberIds'];
    final staffIds = staffRaw is List
        ? staffRaw.map((e) => e.toString()).toList()
        : const <String>[];
    return AgendaService(
      id: AgendaJson.parseString(json['id']),
      businessId: AgendaJson.parseString(json['businessId']),
      nombre: AgendaJson.parseString(json['nombre']),
      descripcion: AgendaJson.parseStringOrNull(json['descripcion']),
      duracionMin: AgendaJson.parseInt(json['duracionMin']),
      precio: AgendaJson.parseDouble(json['precio']),
      activo: AgendaJson.parseBool(json['activo'], fallback: true),
      schedulingMode:
          ServiceSchedulingMode.fromApi(AgendaJson.parseStringOrNull(json['schedulingMode'])),
      staffMemberIds: staffIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgendaService && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
