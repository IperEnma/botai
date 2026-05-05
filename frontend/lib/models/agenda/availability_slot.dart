class AvailabilitySlot {
  final DateTime inicio;
  final DateTime fin;

  const AvailabilitySlot({required this.inicio, required this.fin});

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      inicio: DateTime.parse(json['inicio'] as String),
      fin: DateTime.parse(json['fin'] as String),
    );
  }

  String get label {
    final h = inicio.hour.toString().padLeft(2, '0');
    final m = inicio.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
