import 'package:botai_admin/features/agenda/public/search_screen.dart';
import 'package:botai_admin/models/agenda/business_summary.dart';
import 'package:botai_admin/models/agenda/category.dart';
import 'package:botai_admin/providers/agenda/agenda_api_provider.dart';
import 'package:botai_admin/providers/agenda/public/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_agenda_api.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  testWidgets('SearchScreen muestra empty state hasta que se busca',
      (tester) async {
    final fake = FakeAgendaApiService()
      ..nextCategories = const [
        Category(id: '1', nombre: 'Manicure', slug: 'manicure', synonyms: ['uñas'], activo: true),
      ];

    await _pump(tester, fake);

    expect(find.text('Empezá tu búsqueda'), findsOneWidget);
    expect(find.text('Manicure'), findsOneWidget);
  });

  testWidgets('SearchScreen pinta resultados después del debounce',
      (tester) async {
    final fake = FakeAgendaApiService()
      ..nextSearchResults = const [
        BusinessSummary(
          id: 'b1',
          tenantId: 't1',
          nombre: 'Salón Bella',
          categorias: ['manicure'],
          activo: true,
        ),
      ];

    await _pump(tester, fake, withTenant: 't1');

    await tester.enterText(find.byType(TextField).first, 'uñas');
    // setTenantId fue inyectado al iniciar; el debounce dispara la búsqueda
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Salón Bella'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  FakeAgendaApiService fake, {
  String? withTenant,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        agendaApiServiceProvider.overrideWithValue(fake),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) {
            if (withTenant != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(searchProvider.notifier).setTenantId(withTenant);
              });
            }
            return const SearchScreen();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
