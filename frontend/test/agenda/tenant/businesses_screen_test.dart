import 'package:botai_admin/features/agenda/tenant/businesses_screen.dart';
import 'package:botai_admin/models/agenda/agenda_search_tag.dart';
import 'package:botai_admin/models/agenda/business.dart';
import 'package:botai_admin/providers/agenda/agenda_api_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_agenda_api.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  testWidgets('BusinessesScreen lista negocios cargados', (tester) async {
    final fake = FakeAgendaApiService()
      ..nextBusinesses = const [
        Business(
          id: 'b1',
          tenantId: 't1',
          nombre: 'Salón Bella',
          searchTags: [AgendaSearchTag.profile('belleza')],
          activo: true,
        ),
        Business(
          id: 'b2',
          tenantId: 't1',
          nombre: 'Yoga Center',
          searchTags: [],
          activo: true,
        ),
      ];

    await _pump(tester, fake);

    expect(find.text('Salón Bella'), findsOneWidget);
    expect(find.text('Yoga Center'), findsOneWidget);
  });

  testWidgets('BusinessesScreen muestra empty state si no hay negocios',
      (tester) async {
    final fake = FakeAgendaApiService()..nextBusinesses = const [];

    await _pump(tester, fake);

    expect(find.text('Sin negocios'), findsOneWidget);
  });

  testWidgets('BusinessesScreen agrega negocio via FAB', (tester) async {
    final fake = FakeAgendaApiService()..nextBusinesses = const [];

    await _pump(tester, fake);

    // Tap FAB (extended FAB labeled 'Nuevo negocio')
    await tester.tap(find.text('Nuevo negocio'));
    await tester.pumpAndSettle();

    // Completar el form
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre *'),
      'Nuevo Negocio',
    );
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(fake.createdBusinessNames, contains('Nuevo Negocio'));
    expect(find.text('Nuevo Negocio'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, FakeAgendaApiService fake) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        agendaApiServiceProvider.overrideWithValue(fake),
      ],
      child: const MaterialApp(
        home: BusinessesScreen(tenantId: 't1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
