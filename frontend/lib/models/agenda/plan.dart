import 'agenda_json.dart';

enum PlanTipo {
  ilimitadoMensual,
  porCreditos,
  soloReserva,
  mixto;

  static PlanTipo fromString(String v) {
    switch (v) {
      case 'ILIMITADO_MENSUAL':
        return PlanTipo.ilimitadoMensual;
      case 'POR_CREDITOS':
        return PlanTipo.porCreditos;
      case 'SOLO_RESERVA':
        return PlanTipo.soloReserva;
      case 'MIXTO':
        return PlanTipo.mixto;
      default:
        return PlanTipo.porCreditos;
    }
  }

  String toBackendString() {
    switch (this) {
      case PlanTipo.ilimitadoMensual:
        return 'ILIMITADO_MENSUAL';
      case PlanTipo.porCreditos:
        return 'POR_CREDITOS';
      case PlanTipo.soloReserva:
        return 'SOLO_RESERVA';
      case PlanTipo.mixto:
        return 'MIXTO';
    }
  }

  String get label {
    switch (this) {
      case PlanTipo.ilimitadoMensual:
        return 'Ilimitado mensual';
      case PlanTipo.porCreditos:
        return 'Por créditos';
      case PlanTipo.soloReserva:
        return 'Solo reserva';
      case PlanTipo.mixto:
        return 'Mixto';
    }
  }
}

enum PlanTier {
  vip,
  golden,
  plata;

  static PlanTier? fromStringOrNull(String? v) {
    if (v == null) return null;
    switch (v.toUpperCase()) {
      case 'VIP':
        return PlanTier.vip;
      case 'GOLDEN':
        return PlanTier.golden;
      case 'PLATA':
        return PlanTier.plata;
      default:
        return null;
    }
  }

  String toBackendString() => name.toUpperCase();

  String get label {
    switch (this) {
      case PlanTier.vip:
        return 'VIP';
      case PlanTier.golden:
        return 'Golden';
      case PlanTier.plata:
        return 'Plata';
    }
  }
}

class Plan {
  final String id;
  final String businessId;
  final String nombrePlan;
  final PlanTipo tipo;
  final PlanTier? tier;
  final int totalCreditos;
  final int validezDias;
  final double precio;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Plan({
    required this.id,
    required this.businessId,
    required this.nombrePlan,
    required this.tipo,
    this.tier,
    required this.totalCreditos,
    required this.validezDias,
    required this.precio,
    required this.activo,
    this.createdAt,
    this.updatedAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: AgendaJson.parseString(json['id']),
      businessId: AgendaJson.parseString(json['businessId']),
      nombrePlan: AgendaJson.parseString(json['nombrePlan']),
      tipo: PlanTipo.fromString(AgendaJson.parseString(json['tipo'])),
      tier: PlanTier.fromStringOrNull(json['tier']?.toString()),
      totalCreditos: AgendaJson.parseInt(json['totalCreditos']),
      validezDias: AgendaJson.parseInt(json['validezDias']),
      precio: AgendaJson.parseDouble(json['precio']),
      activo: AgendaJson.parseBool(json['activo'], fallback: true),
      createdAt: AgendaJson.parseDateTimeOrNull(json['createdAt']),
      updatedAt: AgendaJson.parseDateTimeOrNull(json['updatedAt']),
    );
  }

  Plan copyWith({
    String? nombrePlan,
    PlanTipo? tipo,
    Object? tier = _sentinel,
    int? totalCreditos,
    int? validezDias,
    double? precio,
    bool? activo,
  }) {
    return Plan(
      id: id,
      businessId: businessId,
      nombrePlan: nombrePlan ?? this.nombrePlan,
      tipo: tipo ?? this.tipo,
      tier: identical(tier, _sentinel) ? this.tier : tier as PlanTier?,
      totalCreditos: totalCreditos ?? this.totalCreditos,
      validezDias: validezDias ?? this.validezDias,
      precio: precio ?? this.precio,
      activo: activo ?? this.activo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static const _sentinel = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Plan && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
