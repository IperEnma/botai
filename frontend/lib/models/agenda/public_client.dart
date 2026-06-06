class PublicClient {
  final String id;
  final String nombre;
  final String? email;
  final String? telefono;

  // Stats agregadas desde agenda_bookings (sólo presentes en respuestas del
  // panel tenant; `null` / 0 para clientes recién creados).
  final DateTime? clienteDesde;
  final int visitas;
  final int inasistencias;
  final DateTime? ultimaVisita;
  final double gastoAcumulado;

  const PublicClient({
    required this.id,
    required this.nombre,
    this.email,
    this.telefono,
    this.clienteDesde,
    this.visitas = 0,
    this.inasistencias = 0,
    this.ultimaVisita,
    this.gastoAcumulado = 0,
  });

  factory PublicClient.fromJson(Map<String, dynamic> json) => PublicClient(
        id: json['id']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        email: json['email']?.toString(),
        telefono: json['telefono']?.toString(),
        clienteDesde: _parseDate(json['clienteDesde']),
        visitas: _parseInt(json['visitas']),
        inasistencias: _parseInt(json['inasistencias']),
        ultimaVisita: _parseDate(json['ultimaVisita']),
        gastoAcumulado: _parseDouble(json['gastoAcumulado']),
      );
}

DateTime? _parseDate(Object? v) {
  if (v == null) return null;
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

int _parseInt(Object? v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _parseDouble(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
