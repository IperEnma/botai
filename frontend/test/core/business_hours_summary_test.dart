import 'package:flutter_test/flutter_test.dart';
import 'package:botai_admin/core/business_hours_summary.dart';
import 'package:botai_admin/models/agenda/business_hours.dart';

BusinessHours _day(
  int dow, {
  bool cerrado = false,
  String? apertura,
  String? cierre,
  String? apertura2,
  String? cierre2,
}) {
  return BusinessHours(
    id: 'h$dow',
    businessId: 'b1',
    diaSemana: dow,
    apertura: apertura,
    cierre: cierre,
    apertura2: apertura2,
    cierre2: cierre2,
    cerrado: cerrado,
  );
}

void main() {
  test('agrupa lunes a viernes con mismo horario', () {
    final hours = [
      for (var d = 0; d < 5; d++) _day(d, apertura: '09:00', cierre: '18:00'),
      _day(5, apertura: '09:00', cierre: '13:00'),
      _day(6, cerrado: true),
    ];

    final lines = BusinessHoursSummary.lines(hours);
    expect(lines.length, 3);
    expect(lines[0].text, 'Lun – Vie · 09:00 – 18:00');
    expect(lines[1].text, 'Sáb · 09:00 – 13:00');
    expect(lines[2].text, 'Dom · Cerrado');
    expect(lines[2].isClosed, isTrue);
  });

  test('todos los días iguales en una sola línea', () {
    final hours = [
      for (var d = 0; d < 7; d++) _day(d, apertura: '10:00', cierre: '20:00'),
    ];

    final lines = BusinessHoursSummary.lines(hours);
    expect(lines.length, 1);
    expect(lines.single.text, 'Todos los días · 10:00 – 20:00');
  });

  test('turno partido se muestra en el rango', () {
    final hours = [
      _day(
        0,
        apertura: '09:00',
        cierre: '13:00',
        apertura2: '15:00',
        cierre2: '19:00',
      ),
      for (var d = 1; d < 7; d++) _day(d, cerrado: true),
    ];

    final lines = BusinessHoursSummary.lines(hours);
    expect(lines.first.dayLabel, 'Lun');
    expect(lines.first.schedule, '09:00 – 13:00 · 15:00 – 19:00');
  });

  test('sin horarios devuelve lista vacía', () {
    expect(BusinessHoursSummary.lines([]), isEmpty);
  });
}
