import 'agenda_json.dart';

/// Identidad RBAC efectiva del usuario autenticado (espejo de
/// `MeProfileResponse` en backend). Devuelta por `GET /api/agenda/me/profile`.
///
/// Cacheada por `meProfileProvider` para gatear UI sin re-consultar al backend.
class AgendaMeProfile {
  final String? userId;
  final String? email;
  final String? tenantId;
  final List<AgendaRoleAssignment> roles;
  final bool platformAdmin;
  final bool owner;
  final bool tenantAdmin;

  const AgendaMeProfile({
    this.userId,
    this.email,
    this.tenantId,
    required this.roles,
    required this.platformAdmin,
    required this.owner,
    required this.tenantAdmin,
  });

  /// Estado "no resuelto": sin claims, sin roles. Útil para inicializar
  /// providers antes de la primera carga.
  factory AgendaMeProfile.empty() => const AgendaMeProfile(
        roles: [],
        platformAdmin: false,
        owner: false,
        tenantAdmin: false,
      );

  factory AgendaMeProfile.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    final rolesList = rolesRaw is List
        ? rolesRaw
            .whereType<Map<String, dynamic>>()
            .map(AgendaRoleAssignment.fromJson)
            .toList()
        : <AgendaRoleAssignment>[];
    return AgendaMeProfile(
      userId: AgendaJson.parseStringOrNull(json['userId']),
      email: AgendaJson.parseStringOrNull(json['email']),
      tenantId: AgendaJson.parseStringOrNull(json['tenantId']),
      roles: rolesList,
      platformAdmin: json['platformAdmin'] == true,
      owner: json['owner'] == true,
      tenantAdmin: json['tenantAdmin'] == true,
    );
  }

  bool get isAuthenticated => userId != null;

  /// True si el usuario tiene **OWNER** o **TENANT_ADMIN** sobre el tenant
  /// actual. Espeja la lógica del backend `AgendaUserPrincipal.isAdministrative()`
  /// y `@authz.canManageBusiness` (sin la validación de `tenantOwnsBusiness`,
  /// que no aplica para un gate UI dentro del propio tenant).
  ///
  /// Usar este getter para gatear acciones de gestión del negocio: crear/editar
  /// staff, servicios, settings, fotos, planes, etc.
  ///
  /// **No confundir con [tenantAdmin]**, que es literal: "tiene el rol
  /// `TENANT_ADMIN`". Un OWNER puro tiene `tenantAdmin == false`.
  bool get isTenantAdministrative => owner || tenantAdmin;

  /// True si el usuario es **solo STAFF** (STAFF_OPERATOR o STAFF_VIEWER) sin
  /// rol administrativo ni de recepción. Estos usuarios tienen scope reducido
  /// a SU agenda; el frontend les muestra solo el calendario filtrado.
  bool get isStaffOnly {
    if (isTenantAdministrative) return false;
    final hasReception = roles.any((r) => r.role == AgendaRole.reception);
    if (hasReception) return false;
    return roles.any((r) =>
        r.role == AgendaRole.staffOperator ||
        r.role == AgendaRole.staffViewer);
  }

  /// True si el usuario es STAFF_VIEWER puro: sin operator, sin admin, sin
  /// recepción. Solo lectura — no puede crear/modificar reservas ni editar
  /// su horario. La UI esconde botones de mutación y disables editores.
  bool get isStaffViewerOnly {
    if (isTenantAdministrative) return false;
    final hasReception = roles.any((r) => r.role == AgendaRole.reception);
    if (hasReception) return false;
    final hasOperator = roles.any((r) => r.role == AgendaRole.staffOperator);
    if (hasOperator) return false;
    return roles.any((r) => r.role == AgendaRole.staffViewer);
  }

  /// True si el usuario tiene poder de mutación sobre la agenda (admin, OR
  /// recepción, OR STAFF_OPERATOR). Útil para gatear botones de crear /
  /// modificar / cancelar reservas en la UI. STAFF_VIEWER queda fuera.
  bool get canMutateOwnAgenda {
    if (isTenantAdministrative) return true;
    return roles.any((r) =>
        r.role == AgendaRole.reception ||
        r.role == AgendaRole.staffOperator);
  }

  /// True si el usuario tiene rol RECEPTION sin rol administrativo. Recepción
  /// pura: ve y opera la agenda completa del negocio (cualquier profesional)
  /// y gestiona clientes, pero no toca configuración / servicios / equipo /
  /// administradores ni gestiona el bot.
  bool get isReceptionOnly {
    if (isTenantAdministrative) return false;
    return roles.any((r) => r.role == AgendaRole.reception);
  }

  /// Conjunto de sucursales sobre las que el usuario tiene rol RECEPTION.
  /// Útil para limitar el selector de sucursal del panel a las asignadas.
  Set<String> get receptionBusinessIds {
    final result = <String>{};
    for (final r in roles) {
      if (r.role == AgendaRole.reception && r.businessId != null) {
        result.add(r.businessId!);
      }
    }
    return result;
  }

  /// True si el usuario tiene scope reducido a sucursales asignadas (STAFF o
  /// RECEPTION, sin rol administrativo). El panel fuerza la sucursal
  /// seleccionada a una de las permitidas y el sidebar muestra solo lo que
  /// puede operar.
  bool get hasBusinessScopedAccess => isStaffOnly || isReceptionOnly;

  /// Conjunto de sucursales con scope STAFF (operator/viewer) o RECEPTION —
  /// el panel restringe la sucursal seleccionada a este set para non-admins.
  Set<String> get scopedBusinessIds => {
        ...staffBusinessIds,
        ...receptionBusinessIds,
      };

  /// True si el usuario puede gestionar las "operaciones" del negocio
  /// indicado: servicios, equipo y horarios. Espeja
  /// `AgendaAuthorizationService.canManageBusinessOperations` (OW/TA cualquier
  /// negocio del tenant; RC sobre las sucursales asignadas).
  bool canManageBusinessOperations(String businessId) {
    if (isTenantAdministrative) return true;
    return roles.any((r) =>
        r.role == AgendaRole.reception && r.businessId == businessId);
  }

  /// Conjunto de sucursales sobre las que el usuario tiene un rol STAFF
  /// (operator o viewer). Útil para filtrar el selector de sucursal.
  Set<String> get staffBusinessIds {
    final result = <String>{};
    for (final r in roles) {
      if ((r.role == AgendaRole.staffOperator ||
              r.role == AgendaRole.staffViewer) &&
          r.businessId != null) {
        result.add(r.businessId!);
      }
    }
    return result;
  }

  /// Tiene el rol indicado a nivel tenant (sin `businessId`).
  bool hasTenantRole(AgendaRole role) => roles.any((r) =>
      r.role == role && r.businessId == null && r.belongsToCurrentTenant(tenantId));

  /// Tiene el rol indicado sobre una sucursal concreta.
  bool hasBusinessRole(AgendaRole role, String businessId) =>
      roles.any((r) => r.role == role && r.businessId == businessId);

  /// Tiene alguno de los roles operativos sobre la sucursal.
  bool hasAnyBusinessRole(String businessId, List<AgendaRole> candidates) =>
      candidates.any((r) => hasBusinessRole(r, businessId));

  /// Conjunto de sucursales asignadas para un rol dado (RC/SV/SO).
  Set<String> businessesFor(AgendaRole role) => roles
      .where((r) => r.role == role && r.businessId != null)
      .map((r) => r.businessId!)
      .toSet();
}

class AgendaRoleAssignment {
  final AgendaRole role;
  final String? businessId;

  const AgendaRoleAssignment({required this.role, this.businessId});

  factory AgendaRoleAssignment.fromJson(Map<String, dynamic> json) =>
      AgendaRoleAssignment(
        role: AgendaRole.parse(AgendaJson.parseString(json['role'])),
        businessId: AgendaJson.parseStringOrNull(json['businessId']),
      );

  /// True si esta asignación pertenece al tenant indicado (o si es tenant-wide
  /// — el `businessId == null` se valida en el caller).
  bool belongsToCurrentTenant(String? currentTenantId) => currentTenantId != null;
}

/// Roles RBAC del módulo Agenda. Mapean 1:1 con `com.botai.domain.agenda.model.Role`.
enum AgendaRole {
  platformAdmin('PLATFORM_ADMIN'),
  owner('OWNER'),
  tenantAdmin('TENANT_ADMIN'),
  reception('RECEPTION'),
  staffViewer('STAFF_VIEWER'),
  staffOperator('STAFF_OPERATOR'),
  client('CLIENT'),
  unknown('UNKNOWN');

  const AgendaRole(this.code);
  final String code;

  static AgendaRole parse(String raw) {
    for (final r in values) {
      if (r.code == raw) return r;
    }
    return AgendaRole.unknown;
  }
}
