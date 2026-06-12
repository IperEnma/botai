import 'agenda_json.dart';

/// Request al endpoint `POST /api/agenda/me/tenant/invitations`.
class CreateTenantInvitationRequest {
  final String nombre;
  final String email;
  final String? telefono;
  final String role; // STAFF_OPERATOR | STAFF_VIEWER | RECEPTION | TENANT_ADMIN
  final List<String> businessIds;

  const CreateTenantInvitationRequest({
    required this.nombre,
    required this.email,
    required this.role,
    required this.businessIds,
    this.telefono,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'email': email,
        if (telefono != null && telefono!.isNotEmpty) 'telefono': telefono,
        'role': role,
        'businessIds': businessIds,
      };
}

/// Respuesta del endpoint de invitación.
class TenantInvitationResponse {
  final String userId;
  final String email;
  final String nombre;
  final String role;
  final List<String> businessIds;
  final String? staffMemberId;
  final bool userExisted;

  const TenantInvitationResponse({
    required this.userId,
    required this.email,
    required this.nombre,
    required this.role,
    required this.businessIds,
    required this.userExisted,
    this.staffMemberId,
  });

  factory TenantInvitationResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['businessIds'];
    final ids = raw is List
        ? raw.map((e) => e.toString()).toList(growable: false)
        : <String>[];
    return TenantInvitationResponse(
      userId: AgendaJson.parseString(json['userId']),
      email: AgendaJson.parseString(json['email']),
      nombre: AgendaJson.parseString(json['nombre']),
      role: AgendaJson.parseString(json['role']),
      businessIds: ids,
      staffMemberId: AgendaJson.parseStringOrNull(json['staffMemberId']),
      userExisted: json['userExisted'] == true,
    );
  }
}
