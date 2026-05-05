import 'agenda_json.dart';

enum NotificationEstado {
  pendiente,
  enviada,
  fallida,
  leida;

  static NotificationEstado fromString(String v) {
    switch (v.toUpperCase()) {
      case 'PENDIENTE':
        return NotificationEstado.pendiente;
      case 'ENVIADA':
        return NotificationEstado.enviada;
      case 'FALLIDA':
        return NotificationEstado.fallida;
      case 'LEIDA':
        return NotificationEstado.leida;
      default:
        return NotificationEstado.pendiente;
    }
  }

  String get label {
    switch (this) {
      case NotificationEstado.pendiente:
        return 'Pendiente';
      case NotificationEstado.enviada:
        return 'Enviada';
      case NotificationEstado.fallida:
        return 'Fallida';
      case NotificationEstado.leida:
        return 'Leída';
    }
  }

  bool get isRead => this == NotificationEstado.leida;
}

class AgendaNotification {
  final String id;
  final String businessId;
  final String canal;
  final String titulo;
  final String cuerpo;
  final NotificationEstado estado;
  final DateTime createdAt;

  const AgendaNotification({
    required this.id,
    required this.businessId,
    required this.canal,
    required this.titulo,
    required this.cuerpo,
    required this.estado,
    required this.createdAt,
  });

  factory AgendaNotification.fromJson(Map<String, dynamic> json) {
    return AgendaNotification(
      id: AgendaJson.parseString(json['id']),
      businessId: AgendaJson.parseString(json['businessId']),
      canal: AgendaJson.parseString(json['canal']),
      titulo: AgendaJson.parseString(json['titulo']),
      cuerpo: AgendaJson.parseString(json['cuerpo']),
      estado: NotificationEstado.fromString(
          AgendaJson.parseString(json['estado'], fallback: 'ENVIADA')),
      createdAt: AgendaJson.parseDateTime(json['createdAt']),
    );
  }

  AgendaNotification copyWith({NotificationEstado? estado}) {
    return AgendaNotification(
      id: id,
      businessId: businessId,
      canal: canal,
      titulo: titulo,
      cuerpo: cuerpo,
      estado: estado ?? this.estado,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgendaNotification && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
