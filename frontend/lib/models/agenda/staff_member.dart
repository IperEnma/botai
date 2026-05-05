class StaffMember {
  final String id;
  final String businessId;
  final String nombre;
  final String? rol;
  final String? avatarUrl;
  final bool activo;

  const StaffMember({
    required this.id,
    required this.businessId,
    required this.nombre,
    this.rol,
    this.avatarUrl,
    required this.activo,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        nombre: json['nombre'] as String,
        rol: json['rol'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        activo: json['activo'] as bool,
      );
}
