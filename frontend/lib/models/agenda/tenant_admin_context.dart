/// Respuesta de {@code GET /api/agenda/me/tenant-admin} (tenant del admin por email).
class TenantAdminContext {
  const TenantAdminContext({required this.tenantId});

  final String tenantId;

  factory TenantAdminContext.fromJson(Map<String, dynamic> json) {
    final id = json['tenantId'];
    if (id is! String || id.isEmpty) {
      throw FormatException('tenantId inválido en TenantAdminContext');
    }
    return TenantAdminContext(tenantId: id);
  }
}
