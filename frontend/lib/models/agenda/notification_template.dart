import 'agenda_json.dart';

enum NotificationCanal {
  email,
  whatsapp,
  sms,
  push;

  static NotificationCanal fromString(String v) {
    switch (v.toUpperCase()) {
      case 'EMAIL':
        return NotificationCanal.email;
      case 'WHATSAPP':
        return NotificationCanal.whatsapp;
      case 'SMS':
        return NotificationCanal.sms;
      case 'PUSH':
        return NotificationCanal.push;
      default:
        return NotificationCanal.email;
    }
  }

  String toBackendString() => name.toUpperCase();

  String get label {
    switch (this) {
      case NotificationCanal.email:
        return 'Email';
      case NotificationCanal.whatsapp:
        return 'WhatsApp';
      case NotificationCanal.sms:
        return 'SMS';
      case NotificationCanal.push:
        return 'Push';
    }
  }
}

class NotificationTemplate {
  final String id;
  final String businessId;
  final String codigo;
  final NotificationCanal canal;
  final String titulo;
  final String cuerpo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NotificationTemplate({
    required this.id,
    required this.businessId,
    required this.codigo,
    required this.canal,
    required this.titulo,
    required this.cuerpo,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: AgendaJson.parseString(json['id']),
      businessId: AgendaJson.parseString(json['businessId']),
      codigo: AgendaJson.parseString(json['codigo']),
      canal: NotificationCanal.fromString(
          AgendaJson.parseString(json['canal'], fallback: 'EMAIL')),
      titulo: AgendaJson.parseString(json['titulo']),
      cuerpo: AgendaJson.parseString(json['cuerpo']),
      createdAt: AgendaJson.parseDateTimeOrNull(json['createdAt']),
      updatedAt: AgendaJson.parseDateTimeOrNull(json['updatedAt']),
    );
  }

  NotificationTemplate copyWith({
    String? titulo,
    String? cuerpo,
    NotificationCanal? canal,
  }) {
    return NotificationTemplate(
      id: id,
      businessId: businessId,
      codigo: codigo,
      canal: canal ?? this.canal,
      titulo: titulo ?? this.titulo,
      cuerpo: cuerpo ?? this.cuerpo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationTemplate && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
