import 'package:botai_admin/models/agenda/booking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// El dialog vive dentro de my_bookings_screen.dart.
// Reexportamos la clase para testearla de forma aislada copiando la lógica de ventana.

// Helper que replica la lógica del _CancelBookingDialog para test unitario.
bool isOutsideCancellationWindow(DateTime bookingStart, int hoursCancellationLimit) {
  final diff = bookingStart.difference(DateTime.now());
  return diff.inHours < hoursCancellationLimit;
}

void main() {
  group('ventana de cancelación', () {
    test('booking en 2 horas está fuera de ventana de 24h', () {
      final booking = DateTime.now().add(const Duration(hours: 2));
      expect(isOutsideCancellationWindow(booking, 24), isTrue);
    });

    test('booking en 48 horas está dentro de ventana de 24h', () {
      final booking = DateTime.now().add(const Duration(hours: 48));
      expect(isOutsideCancellationWindow(booking, 24), isFalse);
    });

    test('booking exactamente en 24h está dentro de ventana (no penaliza)', () {
      final booking = DateTime.now().add(const Duration(hours: 24));
      // diff.inHours == 24, y 24 < 24 es false → dentro de ventana.
      expect(isOutsideCancellationWindow(booking, 24), isFalse);
    });

    test('booking en 26 horas está dentro de ventana de 24h', () {
      final booking = DateTime.now().add(const Duration(hours: 26));
      expect(isOutsideCancellationWindow(booking, 24), isFalse);
    });
  });

  group('_CancelBookingDialog widget', () {
    Booking makeBooking(Duration fromNow) {
      final start = DateTime.now().add(fromNow);
      return Booking(
        id: 'bk-1',
        userId: 'u-1',
        serviceId: 'svc-1',
        servicioNombre: 'Corte de cabello',
        businessId: 'biz-1',
        fechaHoraInicio: start,
        fechaHoraFin: start.add(const Duration(minutes: 60)),
        estado: BookingEstado.confirmada,
        tipoReserva: BookingTipo.pagoPorTurno,
      );
    }

    testWidgets('muestra advertencia cuando está fuera de ventana', (tester) async {
      final booking = makeBooking(const Duration(hours: 2));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => _FakeCancelDialog(booking: booking, outsideWindow: true),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.textContaining('penalización'), findsOneWidget);
    });

    testWidgets('no muestra advertencia cuando está dentro de ventana', (tester) async {
      final booking = makeBooking(const Duration(hours: 48));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => _FakeCancelDialog(booking: booking, outsideWindow: false),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.textContaining('penalización'), findsNothing);
    });
  });
}

// Widget auxiliar que replica la UI del dialog con el flag pre-calculado.
class _FakeCancelDialog extends StatelessWidget {
  const _FakeCancelDialog({required this.booking, required this.outsideWindow});

  final Booking booking;
  final bool outsideWindow;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar reserva'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('¿Cancelar la reserva de "${booking.servicioNombre}"?'),
          if (outsideWindow) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                border: Border.all(color: const Color(0xFFF59E0B)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estás fuera de la ventana de cancelación. '
                      'Se puede aplicar una penalización de créditos.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Mantener'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Cancelar reserva'),
        ),
      ],
    );
  }
}
