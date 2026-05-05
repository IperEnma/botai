import 'package:botai_admin/features/agenda/me/wallet_screen.dart';
import 'package:botai_admin/models/agenda/wallet.dart';
import 'package:botai_admin/providers/agenda/agenda_api_provider.dart';
import 'package:botai_admin/providers/agenda/me/wallet_provider.dart';
import 'package:botai_admin/services/agenda_api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_agenda_api.dart';

void main() {
  late FakeAgendaApiService fakeApi;

  setUp(() => fakeApi = FakeAgendaApiService());

  Widget buildUnderTest(String subscriptionId) {
    return ProviderScope(
      overrides: [
        agendaApiServiceProvider.overrideWithValue(fakeApi),
      ],
      child: MaterialApp(
        home: WalletScreen(subscriptionId: subscriptionId),
      ),
    );
  }

  testWidgets('muestra saldo y movimientos en orden cronológico inverso',
      (tester) async {
    final now = DateTime.now();
    fakeApi.nextWallet = Wallet(
      subscriptionId: 'sub-1',
      saldoActual: 7,
      fechaExpiracion: now.add(const Duration(days: 30)),
      movimientos: [
        CreditTransaction(
          id: 'tx-1',
          subscriptionId: 'sub-1',
          monto: 10,
          motivo: 'Compra plan',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        CreditTransaction(
          id: 'tx-2',
          subscriptionId: 'sub-1',
          monto: -3,
          motivo: 'Reserva servicio',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ],
    );

    await tester.pumpWidget(buildUnderTest('sub-1'));
    await tester.pumpAndSettle();

    // Header muestra el saldo
    expect(find.text('7 créditos'), findsOneWidget);

    // Ambos movimientos visibles
    expect(find.text('Compra plan'), findsOneWidget);
    expect(find.text('Reserva servicio'), findsOneWidget);

    // Crédito positivo muestra '+'
    expect(find.text('+10'), findsOneWidget);
    // Débito muestra el número negativo
    expect(find.text('-3'), findsOneWidget);
  });

  testWidgets('muestra estado vacío cuando no hay movimientos', (tester) async {
    fakeApi.nextWallet = const Wallet(
      subscriptionId: 'sub-2',
      saldoActual: 0,
      movimientos: [],
    );

    await tester.pumpWidget(buildUnderTest('sub-2'));
    await tester.pumpAndSettle();

    expect(find.text('Sin movimientos'), findsOneWidget);
  });

  testWidgets('muestra error y permite reintentar', (tester) async {
    fakeApi.throwNext = const AgendaApiException(
        message: 'No autorizado', status: 401);

    await tester.pumpWidget(buildUnderTest('sub-err'));
    await tester.pumpAndSettle();

    expect(find.text('No autorizado'), findsOneWidget);
  });
}
