import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botai_admin/features/configuracion/business_config.dart';
import 'package:botai_admin/features/configuracion/config_controller.dart';
import 'package:botai_admin/features/configuracion/widgets/category_chips.dart';
import 'package:botai_admin/features/configuracion/widgets/k_toggle.dart';
import 'package:botai_admin/features/configuracion/widgets/section_card.dart';
import 'package:botai_admin/features/configuracion/widgets/social_row.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('KToggle', () {
    testWidgets('muestra estado inicial ON', (tester) async {
      bool value = true;
      await tester.pumpWidget(
        _wrap(
          KToggle(
            value: value,
            onChanged: (v) => value = v,
            semanticLabel: 'Test toggle',
          ),
        ),
      );
      expect(find.byType(KToggle), findsOneWidget);
    });

    testWidgets('flip: ON → OFF al tocar', (tester) async {
      bool value = true;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (_, setState) => KToggle(
              value: value,
              onChanged: (v) => setState(() => value = v),
              semanticLabel: 'Confirmar reservas',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(KToggle));
      await tester.pumpAndSettle();
      expect(value, isFalse);
    });

    testWidgets('flip: OFF → ON al tocar', (tester) async {
      bool value = false;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (_, setState) => KToggle(
              value: value,
              onChanged: (v) => setState(() => value = v),
              semanticLabel: 'Notificaciones',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(KToggle));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });
  });

  group('CategoryChips', () {
    testWidgets('lista vacía muestra "Sin categorías"', (tester) async {
      await tester.pumpWidget(
        _wrap(const CategoryChips(categorias: [])),
      );
      expect(find.text('Sin categorías'), findsOneWidget);
    });

    testWidgets('lista con items muestra chips', (tester) async {
      await tester.pumpWidget(
        _wrap(const CategoryChips(
          categorias: ['Peluquería', 'Barbería'],
        )),
      );
      expect(find.text('Peluquería'), findsOneWidget);
      expect(find.text('Barbería'), findsOneWidget);
      expect(find.text('Sin categorías'), findsNothing);
    });
  });

  group('SocialRow — estado vacío', () {
    testWidgets('red sin conectar muestra "+ Conectar"', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SocialRow(
            kind: SocialKind.whatsapp,
            handle: null,
            onEdit: () {},
            onConnect: () {},
          ),
        ),
      );
      expect(find.text('+ Conectar'), findsOneWidget);
      expect(find.text('Editar'), findsNothing);
    });

    testWidgets('red conectada muestra "Editar" y handle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SocialRow(
            kind: SocialKind.instagram,
            handle: '@estudionorte.uy',
            onEdit: () {},
            onConnect: () {},
          ),
        ),
      );
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('@estudionorte.uy'), findsOneWidget);
      expect(find.text('+ Conectar'), findsNothing);
    });
  });

  group('SectionCard — botón Editar', () {
    testWidgets('sin onEdit no muestra botón Editar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SectionCard(
            title: 'Test',
            child: const Text('Contenido'),
          ),
        ),
      );
      expect(find.text('Editar'), findsNothing);
    });

    testWidgets('con onEdit muestra botón ghost sin fondo morado', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SectionCard(
            title: 'Test',
            onEdit: () {},
            child: const Text('Contenido'),
          ),
        ),
      );
      expect(find.text('Editar'), findsOneWidget);

      // El botón Editar debe ser ghost: NO debe haber un Container con fondo accent
      final containers = tester.widgetList<Container>(find.descendant(
        of: find.byType(SectionCard),
        matching: find.byType(Container),
      ));
      for (final c in containers) {
        final deco = c.decoration;
        if (deco is BoxDecoration && deco.color != null) {
          // Color accent = 0xFF3B2F63. El botón ghost NO debe usar este color.
          expect(deco.color?.value, isNot(equals(0xFF3B2F63)));
        }
      }
    });
  });

  group('ConfigController — refleja toggles en estado', () {
    const key = ConfigKey('t1', 'b1');

    ConfigController makeCtrl(BusinessConfig initial) {
      late ConfigController ctrl;
      final container = ProviderContainer(overrides: [
        configControllerProvider(key).overrideWith((ref) {
          ctrl = ConfigController(ref, key, initial);
          return ctrl;
        }),
      ]);
      container.read(configControllerProvider(key).notifier);
      return ctrl;
    }

    test('confirmarReservasManual refleja toggle', () {
      final ctrl = makeCtrl(const BusinessConfig(
        nombre: 'Test',
        confirmarReservasManual: false,
      ));
      expect(ctrl.state.config.confirmarReservasManual, isFalse);
      ctrl.toggleConfirmarReservas();
      expect(ctrl.state.config.confirmarReservasManual, isTrue);
    });

    test('notificacionesAutomaticas refleja toggle', () {
      final ctrl = makeCtrl(const BusinessConfig(
        nombre: 'Test',
        notificacionesAutomaticas: true,
      ));
      expect(ctrl.state.config.notificacionesAutomaticas, isTrue);
      ctrl.toggleNotificaciones();
      expect(ctrl.state.config.notificacionesAutomaticas, isFalse);
    });
  });
}
