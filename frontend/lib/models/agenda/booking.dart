import 'agenda_json.dart';

enum BookingEstado {
  pendiente,
  confirmada,
  cancelada,
  completada;

  static BookingEstado fromString(String v) {
    switch (v.toUpperCase()) {
      case 'PENDING':
      case 'PENDIENTE':
        return BookingEstado.pendiente;
      case 'CONFIRMED':
      case 'CONFIRMADA':
        return BookingEstado.confirmada;
      case 'CANCELLED':
      case 'CANCELADA':
        return BookingEstado.cancelada;
      case 'COMPLETED':
      case 'COMPLETADA':
        return BookingEstado.completada;
      case 'NO_SHOW':
        return BookingEstado.cancelada;
      default:
        return BookingEstado.pendiente;
    }
  }

  String get label {
    switch (this) {
      case BookingEstado.pendiente:
        return 'Pendiente';
      case BookingEstado.confirmada:
        return 'Confirmada';
      case BookingEstado.cancelada:
        return 'Cancelada';
      case BookingEstado.completada:
        return 'Completada';
    }
  }

  bool get isCancellable =>
      this == BookingEstado.pendiente || this == BookingEstado.confirmada;
}

enum BookingTipo {
  porSubscripcion,
  pagoPorTurno;

  static BookingTipo fromString(String v) {
    switch (v.toUpperCase()) {
      case 'POR_SUBSCRIPCION':
        return BookingTipo.porSubscripcion;
      case 'PAGO_POR_TURNO':
        return BookingTipo.pagoPorTurno;
      default:
        return BookingTipo.pagoPorTurno;
    }
  }

  String toBackendString() {
    switch (this) {
      case BookingTipo.porSubscripcion:
        return 'POR_SUBSCRIPCION';
      case BookingTipo.pagoPorTurno:
        return 'PAGO_POR_TURNO';
    }
  }

  String get label {
    switch (this) {
      case BookingTipo.porSubscripcion:
        return 'Con suscripción';
      case BookingTipo.pagoPorTurno:
        return 'Pago por turno';
    }
  }
}

class Booking {
  final String id;
  final String userId;
  final String serviceId;
  final String servicioNombre;
  final String businessId;
  final String? subscriptionId;
  final DateTime fechaHoraInicio;
  final DateTime fechaHoraFin;
  final BookingEstado estado;
  final BookingTipo tipoReserva;
  final String? notas;
  final DateTime? createdAt;
  final String? clienteNombre;
  final String? clienteEmail;
  final String? clienteTelefono;
  final String? staffMemberId;

  const Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.servicioNombre,
    required this.businessId,
    this.subscriptionId,
    required this.fechaHoraInicio,
    required this.fechaHoraFin,
    required this.estado,
    required this.tipoReserva,
    this.notas,
    this.createdAt,
    this.clienteNombre,
    this.clienteEmail,
    this.clienteTelefono,
    this.staffMemberId,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: AgendaJson.parseString(json['id']),
      userId: AgendaJson.parseString(json['userId']),
      serviceId: AgendaJson.parseString(json['serviceId']),
      servicioNombre: AgendaJson.parseString(json['servicioNombre'], fallback: ''),
      businessId: AgendaJson.parseString(json['businessId']),
      subscriptionId: AgendaJson.parseStringOrNull(json['subscriptionId']),
      fechaHoraInicio: AgendaJson.parseDateTime(json['fechaHoraInicio']),
      fechaHoraFin: AgendaJson.parseDateTime(json['fechaHoraFin']),
      estado: BookingEstado.fromString(
          AgendaJson.parseString(json['estado'], fallback: 'PENDIENTE')),
      tipoReserva: BookingTipo.fromString(
          AgendaJson.parseString(json['tipoReserva'], fallback: 'PAGO_POR_TURNO')),
      notas: AgendaJson.parseStringOrNull(json['notas']),
      createdAt: AgendaJson.parseDateTimeOrNull(json['createdAt']),
      clienteNombre: AgendaJson.parseStringOrNull(json['clienteNombre']),
      clienteEmail: AgendaJson.parseStringOrNull(json['clienteEmail']),
      clienteTelefono: AgendaJson.parseStringOrNull(json['clienteTelefono']),
      staffMemberId: AgendaJson.parseStringOrNull(json['staffMemberId']),
    );
  }

  Booking copyWith({BookingEstado? estado}) {
    return Booking(
      id: id,
      userId: userId,
      serviceId: serviceId,
      servicioNombre: servicioNombre,
      businessId: businessId,
      subscriptionId: subscriptionId,
      fechaHoraInicio: fechaHoraInicio,
      fechaHoraFin: fechaHoraFin,
      estado: estado ?? this.estado,
      tipoReserva: tipoReserva,
      notas: notas,
      createdAt: createdAt,
      clienteNombre: clienteNombre,
      clienteEmail: clienteEmail,
      clienteTelefono: clienteTelefono,
      staffMemberId: staffMemberId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Booking && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
