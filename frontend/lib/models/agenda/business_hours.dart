/// Horario de un día de la semana para un negocio.
/// diaSemana: 0 = lunes, 6 = domingo.
class BusinessHours {
  final String id;
  final String businessId;
  final int diaSemana;
  final String? apertura;  // "HH:mm"
  final String? cierre;    // "HH:mm"
  final bool cerrado;

  const BusinessHours({
    required this.id,
    required this.businessId,
    required this.diaSemana,
    this.apertura,
    this.cierre,
    required this.cerrado,
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      id: json['id']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      diaSemana: (json['diaSemana'] as num).toInt(),
      apertura: _parseTime(json['apertura']),
      cierre: _parseTime(json['cierre']),
      cerrado: json['cerrado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'diaSemana': diaSemana,
        if (apertura != null) 'apertura': apertura,
        if (cierre != null) 'cierre': cierre,
        'cerrado': cerrado,
      };

  static String? _parseTime(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    // Backend returns "HH:mm:ss" — keep only HH:mm
    if (s.length >= 5) return s.substring(0, 5);
    return s;
  }

  static const dayNames = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves',
    'Viernes', 'Sábado', 'Domingo',
  ];

  String get dayName => dayNames[diaSemana];
}
