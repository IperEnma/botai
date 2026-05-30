import 'package:flutter/material.dart';

import '../../../../../../providers/agenda/tenant/horarios_controller_provider.dart';

class SlotPreview {
  final TimeOfDay time;
  final bool available;

  const SlotPreview({required this.time, required this.available});
}

class SlotsResult {
  final List<SlotPreview> range1;
  final List<SlotPreview> range2;

  const SlotsResult({required this.range1, required this.range2});

  List<SlotPreview> get all => [...range1, ...range2];
}

List<SlotPreview> _buildRange(TimeOfDay from, TimeOfDay to, int slotMin, int step) {
  final result = <SlotPreview>[];
  var cursor = from.hour * 60 + from.minute;
  final end = to.hour * 60 + to.minute;

  while (cursor + slotMin <= end && cursor < 24 * 60) {
    result.add(SlotPreview(
      time: TimeOfDay(hour: cursor ~/ 60, minute: cursor % 60),
      available: true,
    ));
    cursor += step;
  }
  return result;
}

SlotsResult generateSlots({
  required DayDraft day,
  required BookingRulesDraft rules,
  int serviceDurationMin = 30,
}) {
  if (!day.open) return const SlotsResult(range1: [], range2: []);

  final slotMin = rules.byService ? serviceDurationMin : rules.fixedSlotMin;
  final step = slotMin + rules.bufferMin;

  final range1 = _buildRange(day.from1, day.to1, slotMin, step);
  final range2 = day.hasBreak
      ? _buildRange(day.from2, day.to2, slotMin, step)
      : <SlotPreview>[];

  return SlotsResult(range1: range1, range2: range2);
}
