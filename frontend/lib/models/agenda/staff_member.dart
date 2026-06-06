import 'agenda_json.dart';

class StaffMember {
  final String id;
  final String businessId;
  final String nombre;
  final String? rol;
  final String? avatarUrl;
  final String? telefono;
  final String? email;
  final String? bio;
  final String? color;
  final bool activo;
  final String status; // 'ACTIVO', 'PAUSADO'
  final Map<String, dynamic>? customSchedule;
  final List<String> serviceIds;
  /// Promedio de reseñas del profesional (null si aún no hay reseñas).
  final double? rating;
  /// Cantidad total de reseñas del profesional.
  final int reviewCount;

  const StaffMember({
    required this.id,
    required this.businessId,
    required this.nombre,
    this.rol,
    this.avatarUrl,
    this.telefono,
    this.email,
    this.bio,
    this.color,
    required this.activo,
    required this.status,
    this.customSchedule,
    this.serviceIds = const [],
    this.rating,
    this.reviewCount = 0,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        nombre: json['nombre'] as String,
        rol: json['rol'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        telefono: json['telefono'] as String?,
        email: json['email'] as String?,
        bio: json['bio'] as String?,
        color: json['color'] as String?,
        activo: json['activo'] as bool? ?? true,
        status: json['status'] as String? ??
            ((json['activo'] as bool?) == true ? 'ACTIVO' : 'PAUSADO'),
        customSchedule: json['customSchedule'] as Map<String, dynamic>?,
        serviceIds: (json['serviceIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        rating: AgendaJson.parseDoubleOrNull(json['rating']),
        reviewCount: AgendaJson.parseInt(json['reviewCount']),
      );
}
