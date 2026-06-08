import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:botai_admin/core/agenda_icon_registry.dart';

void main() {
  group('AgendaIconRegistry.forKey', () {
    test('returns mapped icon for known key', () {
      expect(
        AgendaIconRegistry.forKey('scissors'),
        Icons.content_cut_rounded,
      );
    });

    test('falls back to store for unknown key', () {
      expect(
        AgendaIconRegistry.forKey('unknown_xyz'),
        Icons.storefront_outlined,
      );
    });
  });

  group('AgendaIconRegistry.forCategory', () {
    test('prefers icono from API over slug fallback', () {
      expect(
        AgendaIconRegistry.forCategory(slug: 'peluqueria', icono: 'razor'),
        Icons.cut_rounded,
      );
    });

    test('resolves slug fallback when icono absent', () {
      expect(
        AgendaIconRegistry.forCategory(slug: 'barberia'),
        Icons.cut_rounded,
      );
    });
  });

  group('AgendaIconRegistry.forService', () {
    test('matches service name keywords', () {
      expect(
        AgendaIconRegistry.forService('Corte de barba y fade'),
        Icons.cut_rounded,
      );
      expect(
        AgendaIconRegistry.forService('Consulta médica general'),
        Icons.medical_services_outlined,
      );
      expect(
        AgendaIconRegistry.forService('Sesión de pilates reformer'),
        Icons.sports_gymnastics_outlined,
      );
    });

    test('falls back to business category slug', () {
      expect(
        AgendaIconRegistry.forService(
          'Turno',
          categorySlugs: ['odontologia'],
        ),
        Icons.healing_outlined,
      );
    });
  });
}
