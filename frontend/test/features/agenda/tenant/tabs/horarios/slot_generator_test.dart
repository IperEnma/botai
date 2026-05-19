import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botai_admin/features/agenda/tenant/tabs/horarios/utils/slot_generator.dart';
import 'package:botai_admin/providers/agenda/tenant/horarios_controller_provider.dart';

void main() {
  const defaultRules = BookingRulesDraft(
    byService: false,
    fixedSlotMin: 30,
    bufferMin: 10,
    minLeadHours: 2,
    maxLeadDays: 60,
  );

  DayDraft openDay({
    TimeOfDay from1 = const TimeOfDay(hour: 9, minute: 0),
    TimeOfDay to1 = const TimeOfDay(hour: 19, minute: 0),
    bool hasBreak = false,
    TimeOfDay from2 = const TimeOfDay(hour: 15, minute: 0),
    TimeOfDay to2 = const TimeOfDay(hour: 19, minute: 0),
  }) =>
      DayDraft(
        diaSemana: 0,
        open: true,
        from1: from1,
        to1: to1,
        hasBreak: hasBreak,
        from2: from2,
        to2: to2,
      );

  test('día 09:00–19:00 corrido, buffer 10, slot 30 → slots cada 40 min', () {
    final day = openDay(
      from1: const TimeOfDay(hour: 9, minute: 0),
      to1: const TimeOfDay(hour: 19, minute: 0),
    );
    final slots = generateSlots(
      day: day,
      rules: defaultRules, // fixedSlot=30, buffer=10
    );
    // Step = 40 min (30 slot + 10 buffer).
    // From 09:00: 09:00, 09:40, 10:20, ... last = 18:20 (18:20+30=18:50 ≤ 19:00).
    // 18:20+40=19:00, 19:00+30=19:30 > 19:00 → stop.
    expect(slots, isNotEmpty);
    for (var i = 0; i < slots.length - 1; i++) {
      final t1 = slots[i].time.hour * 60 + slots[i].time.minute;
      final t2 = slots[i + 1].time.hour * 60 + slots[i + 1].time.minute;
      expect(t2 - t1, 40, reason: 'Step should be 40 min (30+10)');
    }
    expect(slots.first.time, const TimeOfDay(hour: 9, minute: 0));
    expect(slots.last.time, const TimeOfDay(hour: 18, minute: 20));
    // All available
    expect(slots.every((s) => s.available), isTrue);
  });

  test('día cerrado → lista vacía', () {
    final day = DayDraft(
      diaSemana: 0,
      open: false,
      from1: const TimeOfDay(hour: 9, minute: 0),
      to1: const TimeOfDay(hour: 18, minute: 0),
    );
    final slots = generateSlots(day: day, rules: defaultRules);
    expect(slots, isEmpty);
  });

  test('día con 2 rangos 09–13 + 15–19, buffer 0, slot 60 → 4 + 4 = 8 slots',
      () {
    final day = openDay(
      from1: const TimeOfDay(hour: 9, minute: 0),
      to1: const TimeOfDay(hour: 13, minute: 0),
      hasBreak: true,
      from2: const TimeOfDay(hour: 15, minute: 0),
      to2: const TimeOfDay(hour: 19, minute: 0),
    );
    const rules = BookingRulesDraft(
      byService: false,
      fixedSlotMin: 60,
      bufferMin: 0,
    );
    final slots = generateSlots(day: day, rules: rules);
    // Range1: 09,10,11,12 (09+60=10, 10+60=11, 11+60=12, 12+60=13≤13) → 4
    // Range2: 15,16,17,18 → 4
    expect(slots.length, 8);
    expect(slots[0].time, const TimeOfDay(hour: 9, minute: 0));
    expect(slots[3].time, const TimeOfDay(hour: 12, minute: 0));
    expect(slots[4].time, const TimeOfDay(hour: 15, minute: 0));
    expect(slots[7].time, const TimeOfDay(hour: 18, minute: 0));
  });

  test('byService=true usa serviceDurationMin proporcionado', () {
    final day = openDay(
      from1: const TimeOfDay(hour: 9, minute: 0),
      to1: const TimeOfDay(hour: 10, minute: 0),
    );
    const rules = BookingRulesDraft(
      byService: true,
      fixedSlotMin: 60,
      bufferMin: 0,
    );
    // serviceDurationMin=30: slots at 09:00, 09:30
    final slots = generateSlots(day: day, rules: rules, serviceDurationMin: 30);
    expect(slots.length, 2);
    expect(slots[0].time, const TimeOfDay(hour: 9, minute: 0));
    expect(slots[1].time, const TimeOfDay(hour: 9, minute: 30));
  });
}
