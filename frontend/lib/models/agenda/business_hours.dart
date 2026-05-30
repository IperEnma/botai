/// Horario de un día de la semana para un negocio.
/// diaSemana: 0 = lunes, 6 = domingo.
class BusinessHours {
  final String id;
  final String businessId;
  final int diaSemana;
  final String? apertura;   // "HH:mm"
  final String? cierre;     // "HH:mm"
  final String? apertura2;  // "HH:mm" — start of second range (after break)
  final String? cierre2;    // "HH:mm" — end of second range (after break)
  final bool cerrado;

  const BusinessHours({
    required this.id,
    required this.businessId,
    required this.diaSemana,
    this.apertura,
    this.cierre,
    this.apertura2,
    this.cierre2,
    required this.cerrado,
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      id: json['id']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      diaSemana: (json['diaSemana'] as num).toInt(),
      apertura: _parseTime(json['apertura']),
      cierre: _parseTime(json['cierre']),
      apertura2: _parseTime(json['apertura2']),
      cierre2: _parseTime(json['cierre2']),
      cerrado: json['cerrado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'diaSemana': diaSemana,
        if (apertura != null) 'apertura': apertura,
        if (cierre != null) 'cierre': cierre,
        if (apertura2 != null) 'apertura2': apertura2,
        if (cierre2 != null) 'cierre2': cierre2,
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
