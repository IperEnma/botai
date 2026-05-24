import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botai_admin/models/agenda/business_hours.dart';
import 'package:botai_admin/providers/agenda/tenant/horarios_controller_provider.dart';

// ── Pure state mutation helpers (no provider needed) ─────────────────────────
//
// These replicate the mutation logic from HorariosNotifier so we can unit-test
// each mutation in isolation without requiring a full Riverpod tree.

HorariosState stateFromHours(List<BusinessHours> hours) {
  final days = daysFromHours(hours);
  return HorariosState(
    days: days,
    savedDays: List.from(days),
    isLoading: false,
  );
}

List<DayDraft> daysFromHours(List<BusinessHours> hours) {
  final map = {for (final h in hours) h.diaSemana: h};
  return List.generate(7, (i) {
    final h = map[i];
    if (h == null || h.cerrado) {
      return DayDraft(
        diaSemana: i,
        open: false,
        from1: const TimeOfDay(hour: 9, minute: 0),
        to1: const TimeOfDay(hour: 13, minute: 0),
        from2: const TimeOfDay(hour: 15, minute: 0),
        to2: const TimeOfDay(hour: 19, minute: 0),
      );
    }
    return DayDraft(
      diaSemana: i,
      open: true,
      from1: parseTime(h.apertura, const TimeOfDay(hour: 9, minute: 0)),
      to1: parseTime(h.cierre, const TimeOfDay(hour: 18, minute: 0)),
    );
  });
}

TimeOfDay parseTime(String? s, TimeOfDay fallback) {
  if (s == null || s.isEmpty) return fallback;
  final parts = s.split(':');
  if (parts.length < 2) return fallback;
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? fallback.hour,
    minute: int.tryParse(parts[1]) ?? fallback.minute,
  );
}

HorariosState applyToggleDay(HorariosState state, int diaSemana) {
  final updated = state.days.map((d) {
    if (d.diaSemana == diaSemana) return d.copyWith(open: !d.open);
    return d;
  }).toList();
  return state.copyWith(days: updated);
}

HorariosState applyAddBreak(HorariosState state, int diaSemana) {
  final updated = state.days.map((d) {
    if (d.diaSemana == diaSemana) return d.copyWith(hasBreak: true);
    return d;
  }).toList();
  return state.copyWith(days: updated);
}

HorariosState applyCopyDayTo(
    HorariosState state, int source, List<int> targets) {
  final src = state.days.firstWhere((d) => d.diaSemana == source);
  final updated = state.days.map((d) {
    if (!targets.contains(d.diaSemana)) return d;
    return DayDraft(
      diaSemana: d.diaSemana,
      open: src.open,
      from1: src.from1,
      to1: src.to1,
      hasBreak: src.hasBreak,
      from2: src.from2,
      to2: src.to2,
    );
  }).toList();
  return state.copyWith(days: updated);
}

HorariosState applyRevert(HorariosState state) {
  return state.copyWith(
    days: List.from(state.savedDays),
    exceptions: List.from(state.savedExceptions),
    rules: state.savedRules,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // Baseline: Mon-Fri open 09-18, Sat+Sun closed
  final baseHours = List.generate(7, (i) {
    if (i < 5) {
      return BusinessHours(
        id: '$i',
        businessId: 'biz1',
        diaSemana: i,
        apertura: '09:00',
        cierre: '18:00',
        cerrado: false,
      );
    }
    return BusinessHours(
      id: '$i',
      businessId: 'biz1',
      diaSemana: i,
      cerrado: true,
    );
  });

  late HorariosState initial;

  setUp(() {
    initial = stateFromHours(baseHours);
  });

  group('toggleDay', () {
    test('toggles open → closed for an open day', () {
      final state = applyToggleDay(initial, 0); // Lunes open → closed
      expect(state.days[0].open, isFalse);
      expect(state.hasChanges, isTrue);
    });

    test('toggles closed → open for a closed day', () {
      final state = applyToggleDay(initial, 6); // Domingo closed → open
      expect(state.days[6].open, isTrue);
      expect(state.hasChanges, isTrue);
    });

    test('other days are not affected', () {
      final state = applyToggleDay(initial, 0);
      for (var i = 1; i < 7; i++) {
        expect(state.days[i].open, initial.days[i].open);
      }
    });
  });

  group('addBreak', () {
    test('sets hasBreak true and marks hasChanges', () {
      final state = applyAddBreak(initial, 1); // Martes
      expect(state.days[1].hasBreak, isTrue);
      expect(state.hasChanges, isTrue);
    });

    test('other days unaffected', () {
      final state = applyAddBreak(initial, 1);
      for (var i = 0; i < 7; i++) {
        if (i != 1) {
          expect(state.days[i].hasBreak, isFalse);
        }
      }
    });
  });

  group('copyDayTo', () {
    test('copies open status and times from Lunes to Martes', () {
      final stateWithMod = initial.copyWith(
        days: initial.days.map((d) {
          if (d.diaSemana == 0) {
            return d.copyWith(
              from1: const TimeOfDay(hour: 10, minute: 0),
              to1: const TimeOfDay(hour: 20, minute: 0),
            );
          }
          return d;
        }).toList(),
      );
      final copied = applyCopyDayTo(stateWithMod, 0, [1]);
      expect(copied.days[1].from1, const TimeOfDay(hour: 10, minute: 0));
      expect(copied.days[1].to1, const TimeOfDay(hour: 20, minute: 0));
      expect(copied.days[1].open, copied.days[0].open);
    });

    test('does not touch source day', () {
      final copied = applyCopyDayTo(initial, 0, [1, 2]);
      expect(copied.days[0], initial.days[0]);
    });

    test('copies to multiple targets', () {
      final copied = applyCopyDayTo(initial, 0, [5, 6]); // Mon → Sat, Sun
      expect(copied.days[5].open, initial.days[0].open);
      expect(copied.days[6].open, initial.days[0].open);
    });
  });

  group('revert', () {
    test('restores draft to saved state', () {
      var state = applyToggleDay(initial, 0);
      state = applyAddBreak(state, 1);
      expect(state.hasChanges, isTrue);

      final reverted = applyRevert(state);
      expect(reverted.hasChanges, isFalse);
      for (var i = 0; i < 7; i++) {
        expect(reverted.days[i], initial.days[i]);
      }
    });

    test('revert without changes keeps state identical', () {
      final reverted = applyRevert(initial);
      expect(reverted.hasChanges, isFalse);
    });
  });

  group('hasChanges', () {
    test('no changes → false', () {
      expect(initial.hasChanges, isFalse);
    });

    test('rules change → true', () {
      final state = initial.copyWith(
        rules: initial.rules.copyWith(bufferMin: 15),
      );
      expect(state.hasChanges, isTrue);
    });

    test('exception added → true', () {
      final exc = ExceptionDraft(
        id: '1',
        type: ExcType.closed,
        dateFrom: DateTime.now(),
        dateTo: DateTime.now(),
      );
      final state = initial.copyWith(exceptions: [exc]);
      expect(state.hasChanges, isTrue);
    });
  });
}
