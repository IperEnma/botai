import 'agenda_json.dart';

enum LoyaltySuggestionEstado {
  pendiente,
  aceptada,
  rechazada,
  enviada;

  static LoyaltySuggestionEstado fromString(String v) {
    switch (v.toUpperCase()) {
      case 'PENDIENTE':
        return LoyaltySuggestionEstado.pendiente;
      case 'ACEPTADA':
        return LoyaltySuggestionEstado.aceptada;
      case 'RECHAZADA':
        return LoyaltySuggestionEstado.rechazada;
      case 'ENVIADA':
        return LoyaltySuggestionEstado.enviada;
      default:
        return LoyaltySuggestionEstado.pendiente;
    }
  }

  String toBackendString() => name.toUpperCase();

  String get label {
    switch (this) {
      case LoyaltySuggestionEstado.pendiente:
        return 'Pendiente';
      case LoyaltySuggestionEstado.aceptada:
        return 'Aceptada';
      case LoyaltySuggestionEstado.rechazada:
        return 'Rechazada';
      case LoyaltySuggestionEstado.enviada:
        return 'Enviada';
    }
  }
}

class LoyaltySuggestion {
  final String id;
  final String businessId;
  final String userId;
  final String triggerRule;
  final LoyaltySuggestionEstado estado;
  final DateTime createdAt;

  const LoyaltySuggestion({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.triggerRule,
    required this.estado,
    required this.createdAt,
  });

  factory LoyaltySuggestion.fromJson(Map<String, dynamic> json) {
    return LoyaltySuggestion(
      id: AgendaJson.parseString(json['id']),
      businessId: AgendaJson.parseString(json['businessId']),
      userId: AgendaJson.parseString(json['userId']),
      triggerRule: AgendaJson.parseString(json['triggerRule']),
      estado: LoyaltySuggestionEstado.fromString(
          AgendaJson.parseString(json['estado'], fallback: 'PENDIENTE')),
      createdAt: AgendaJson.parseDateTime(json['createdAt']),
    );
  }

  LoyaltySuggestion copyWith({LoyaltySuggestionEstado? estado}) {
    return LoyaltySuggestion(
      id: id,
      businessId: businessId,
      userId: userId,
      triggerRule: triggerRule,
      estado: estado ?? this.estado,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoyaltySuggestion && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
