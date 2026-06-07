import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botai_admin/features/configuracion/business_config.dart';
import 'package:botai_admin/features/configuracion/config_controller.dart';

const _key = ConfigKey('t1', 'b1');

ConfigController _makeController(BusinessConfig initial) {
  late ConfigController ctrl;
  final container = ProviderContainer(overrides: [
    configControllerProvider(_key).overrideWith(
      (ref) {
        ctrl = ConfigController(ref, _key, initial);
        return ctrl;
      },
    ),
  ]);
  container.read(configControllerProvider(_key).notifier);
  return ctrl;
}

void main() {
  group('validate — nombre', () {
    test('nombre vacío bloquea guardar', () {
      final ctrl = _makeController(const BusinessConfig(nombre: ''));
      expect(ctrl.validate(), isFalse);
      expect(ctrl.state.nombError, isNotNull);
      expect(ctrl.state.canSave, isFalse);
    });

    test('setNombre con espacios produce error', () {
      final ctrl = _makeController(const BusinessConfig(nombre: 'Test'));
      ctrl.setNombre('   ');
      expect(ctrl.state.nombError, isNotNull);
    });

    test('nombre válido pasa validación', () {
      final ctrl = _makeController(const BusinessConfig(nombre: 'Mi negocio'));
      expect(ctrl.validate(), isTrue);
      expect(ctrl.state.nombError, isNull);
    });
  });

  group('validate — números negativos', () {
    test('horasLimiteCancelacion negativo bloquea guardar', () {
      final ctrl = _makeController(
        const BusinessConfig(nombre: 'Test', horasLimiteCancelacion: -1),
      );
      expect(ctrl.validate(), isFalse);
      expect(ctrl.state.horasError, isNotNull);
    });

    test('diasAntesDeAlertar negativo bloquea guardar', () {
      final ctrl = _makeController(
        const BusinessConfig(nombre: 'Test', diasAntesDeAlertar: -3),
      );
      expect(ctrl.validate(), isFalse);
      expect(ctrl.state.diasError, isNotNull);
    });

    test('creditosMinimosAlertar negativo bloquea guardar', () {
      final ctrl = _makeController(
        const BusinessConfig(nombre: 'Test', creditosMinimosAlertar: -1),
      );
      expect(ctrl.validate(), isFalse);
      expect(ctrl.state.creditosError, isNotNull);
    });

    test('valores en cero son válidos', () {
      final ctrl = _makeController(
        const BusinessConfig(
          nombre: 'Test',
          horasLimiteCancelacion: 0,
          diasAntesDeAlertar: 0,
          creditosMinimosAlertar: 0,
        ),
      );
      expect(ctrl.validate(), isTrue);
    });
  });

  group('setHorasLimiteCancelacion — parsing', () {
    test('string vacío produce error', () {
      final ctrl = _makeController(const BusinessConfig(nombre: 'Test'));
      ctrl.setHorasLimiteCancelacion('');
      expect(ctrl.state.horasError, isNotNull);
    });

    test('string negativo produce error', () {
      final ctrl = _makeController(const BusinessConfig(nombre: 'Test'));
      ctrl.setHorasLimiteCancelacion('-2');
      expect(ctrl.state.horasError, isNotNull);
    });

    test('valor válido actualiza config', () {
      final ctrl = _makeController(const BusinessConfig(nombre: 'Test'));
      ctrl.setHorasLimiteCancelacion('8');
      expect(ctrl.state.horasError, isNull);
      expect(ctrl.state.config.horasLimiteCancelacion, 8);
    });
  });

  group('validate — teléfono', () {
    test('teléfono sin formato internacional falla', () {
      final ctrl = _makeController(
        const BusinessConfig(nombre: 'Test', whatsapp: 'abc'),
      );
      expect(ctrl.validate(), isFalse);
      expect(ctrl.state.whatsappError, isNotNull);
    });

    test('teléfono válido pasa', () {
      final ctrl = _makeController(
        const BusinessConfig(nombre: 'Test', whatsapp: '+598 99 234 567'),
      );
      expect(ctrl.validate(), isTrue);
      expect(ctrl.state.whatsappError, isNull);
    });

    test('whatsapp null es válido (campo opcional)', () {
      final ctrl = _makeController(const BusinessConfig(nombre: 'Test'));
      expect(ctrl.validate(), isTrue);
    });
  });

  group('validate — email', () {
    test('email inválido rechazado', () {
      final ctrl = _makeController(
        const BusinessConfig(nombre: 'Test', email: 'notanemail'),
      );
      expect(ctrl.validate(), isFalse);
      expect(ctrl.state.emailError, isNotNull);
    });

    test('email sin dominio rechazado', () {
      final ctrl = _makeController(
        const BusinessConfig(nombre: 'Test', email: 'user@'),
      );
      expect(ctrl.validate(), isFalse);
      expect(ctrl.state.emailError, isNotNull);
    });

    test('email válido pasa', () {
      final ctrl = _makeController(
        const BusinessConfig(nombre: 'Test', email: 'user@example.com'),
      );
      expect(ctrl.validate(), isTrue);
      expect(ctrl.state.emailError, isNull);
    });

    test('email null es válido (campo opcional)', () {
      final ctrl = _makeController(const BusinessConfig(nombre: 'Test'));
      expect(ctrl.validate(), isTrue);
    });
  });

  group('toggles', () {
    test('toggleConfirmarReservas invierte el valor', () {
      final ctrl = _makeController(
        const BusinessConfig(nombre: 'Test', confirmarReservasManual: true),
      );
      ctrl.toggleConfirmarReservas();
      expect(ctrl.state.config.confirmarReservasManual, isFalse);
      ctrl.toggleConfirmarReservas();
      expect(ctrl.state.config.confirmarReservasManual, isTrue);
    });

    test('toggleNotificaciones invierte el valor', () {
      final ctrl = _makeController(
        const BusinessConfig(nombre: 'Test', notificacionesAutomaticas: true),
      );
      ctrl.toggleNotificaciones();
      expect(ctrl.state.config.notificacionesAutomaticas, isFalse);
    });
  });

  group('canSave', () {
    test('false con nombre vacío', () {
      final ctrl = _makeController(const BusinessConfig(nombre: ''));
      ctrl.validate();
      expect(ctrl.state.canSave, isFalse);
    });

    test('false con número negativo', () {
      final ctrl = _makeController(
        const BusinessConfig(nombre: 'Test', horasLimiteCancelacion: -1),
      );
      ctrl.validate();
      expect(ctrl.state.canSave, isFalse);
    });

    test('true con datos válidos', () {
      final ctrl = _makeController(const BusinessConfig(nombre: 'Test'));
      ctrl.validate();
      expect(ctrl.state.canSave, isTrue);
    });
  });
}
