import 'dart:convert';

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
        id: AgendaJson.parseString(json['id']),
        businessId: AgendaJson.parseString(json['businessId']),
        nombre: AgendaJson.parseString(json['nombre']),
        rol: AgendaJson.parseStringOrNull(json['rol']),
        avatarUrl: AgendaJson.parseStringOrNull(json['avatarUrl']),
        telefono: AgendaJson.parseStringOrNull(json['telefono']),
        email: AgendaJson.parseStringOrNull(json['email']),
        bio: AgendaJson.parseStringOrNull(json['bio']),
        color: AgendaJson.parseStringOrNull(json['color']),
        activo: AgendaJson.parseBool(json['activo'], fallback: true),
        status: AgendaJson.parseStringOrNull(json['status']) ??
            (AgendaJson.parseBool(json['activo'], fallback: true)
                ? 'ACTIVO'
                : 'PAUSADO'),
        customSchedule: _parseCustomSchedule(json['customSchedule']),
        serviceIds: AgendaJson.parseStringList(json['serviceIds']),
        rating: AgendaJson.parseDoubleOrNull(json['rating']),
        reviewCount: AgendaJson.parseInt(json['reviewCount']),
      );

  static Map<String, dynamic>? _parseCustomSchedule(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
