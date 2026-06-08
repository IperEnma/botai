import 'package:flutter_test/flutter_test.dart';
import 'package:botai_admin/core/business_open_status.dart';
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
  final monFri = [
    for (var d = 0; d < 5; d++)
      _day(d, apertura: '09:00', cierre: '18:00'),
    _day(5, apertura: '09:00', cierre: '13:00'),
    _day(6, cerrado: true),
  ];

  test('abierto durante el primer turno', () {
    // 2026-06-08 is Monday
    final status = BusinessOpenStatus.fromHours(
      monFri,
      now: DateTime(2026, 6, 8, 10, 30),
    );
    expect(status?.isOpen, isTrue);
    expect(status?.label, 'Abierto - cierra a las 18:00');
  });

  test('cerrado antes de abrir hoy', () {
    final status = BusinessOpenStatus.fromHours(
      monFri,
      now: DateTime(2026, 6, 8, 8, 0),
    );
    expect(status?.isOpen, isFalse);
    expect(status?.label, 'Cerrado - abre a las 09:00');
  });

  test('cerrado con turno partido entre rangos', () {
    final hours = [
      _day(
        0,
        apertura: '09:00',
        cierre: '13:00',
        apertura2: '15:00',
        cierre2: '19:00',
      ),
    ];
    final status = BusinessOpenStatus.fromHours(
      hours,
      now: DateTime(2026, 6, 8, 14, 0),
    );
    expect(status?.isOpen, isFalse);
    expect(status?.label, 'Cerrado - abre a las 15:00');
  });

  test('cerrado domingo indica proxima apertura', () {
    final status = BusinessOpenStatus.fromHours(
      monFri,
      now: DateTime(2026, 6, 7, 12, 0), // Sunday
    );
    expect(status?.isOpen, isFalse);
    expect(status?.label, 'Cerrado - abre mañana a las 09:00');
  });

  test('sin horarios no muestra estado', () {
    expect(BusinessOpenStatus.fromHours([]), isNull);
  });
}
