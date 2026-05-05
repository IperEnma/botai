import 'agenda_json.dart';

enum SubscriptionEstado {
  activa,
  expirada,
  cancelada,
  agotada;

  static SubscriptionEstado fromString(String v) {
    switch (v.toUpperCase()) {
      case 'ACTIVA':
        return SubscriptionEstado.activa;
      case 'EXPIRADA':
        return SubscriptionEstado.expirada;
      case 'CANCELADA':
        return SubscriptionEstado.cancelada;
      case 'AGOTADA':
        return SubscriptionEstado.agotada;
      default:
        return SubscriptionEstado.activa;
    }
  }

  String get label {
    switch (this) {
      case SubscriptionEstado.activa:
        return 'Activa';
      case SubscriptionEstado.expirada:
        return 'Expirada';
      case SubscriptionEstado.cancelada:
        return 'Cancelada';
      case SubscriptionEstado.agotada:
        return 'Agotada';
    }
  }

  bool get isActive => this == SubscriptionEstado.activa;
}

class Subscription {
  final String id;
  final String userId;
  final String planId;
  final String businessId;
  final int saldoActual;
  final DateTime fechaInicio;
  final DateTime? fechaExpiracion;
  final SubscriptionEstado estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.businessId,
    required this.saldoActual,
    required this.fechaInicio,
    this.fechaExpiracion,
    required this.estado,
    this.createdAt,
    this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: AgendaJson.parseString(json['id']),
      userId: AgendaJson.parseString(json['userId']),
      planId: AgendaJson.parseString(json['planId']),
      businessId: AgendaJson.parseString(json['businessId']),
      saldoActual: AgendaJson.parseInt(json['saldoActual']),
      fechaInicio: AgendaJson.parseDateTime(json['fechaInicio']),
      fechaExpiracion: AgendaJson.parseDateTimeOrNull(json['fechaExpiracion']),
      estado: SubscriptionEstado.fromString(
          AgendaJson.parseString(json['estado'], fallback: 'ACTIVA')),
      createdAt: AgendaJson.parseDateTimeOrNull(json['createdAt']),
      updatedAt: AgendaJson.parseDateTimeOrNull(json['updatedAt']),
    );
  }

  Subscription copyWith({
    int? saldoActual,
    DateTime? fechaExpiracion,
    SubscriptionEstado? estado,
  }) {
    return Subscription(
      id: id,
      userId: userId,
      planId: planId,
      businessId: businessId,
      saldoActual: saldoActual ?? this.saldoActual,
      fechaInicio: fechaInicio,
      fechaExpiracion: fechaExpiracion ?? this.fechaExpiracion,
      estado: estado ?? this.estado,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subscription && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
