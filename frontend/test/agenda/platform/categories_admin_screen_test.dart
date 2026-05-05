import 'package:botai_admin/features/agenda/platform/categories_admin_screen.dart';
import 'package:botai_admin/models/agenda/category.dart';
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

  testWidgets('CategoriesAdminScreen lista categorías cargadas', (tester) async {
    final fake = FakeAgendaApiService()
      ..nextPlatformCategories = const [
        Category(id: '1', nombre: 'Manicure', slug: 'manicure', synonyms: ['uñas'], activo: true),
        Category(id: '2', nombre: 'Yoga', slug: 'yoga', synonyms: [], activo: true),
      ];

    await _pump(tester, fake);

    expect(find.text('Manicure'), findsOneWidget);
    expect(find.text('Yoga'), findsOneWidget);
    expect(find.text('slug: manicure'), findsOneWidget);
  });

  testWidgets('CategoriesAdminScreen muestra empty state si no hay categorías',
      (tester) async {
    final fake = FakeAgendaApiService()..nextPlatformCategories = const [];

    await _pump(tester, fake);

    expect(find.text('Sin categorías todavía'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, FakeAgendaApiService fake) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        agendaApiServiceProvider.overrideWithValue(fake),
      ],
      child: const MaterialApp(home: CategoriesAdminScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
