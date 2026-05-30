import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/business_hours.dart';
import 'business_hours_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Domain models (local draft)
// ─────────────────────────────────────────────────────────────────────────────

class DayDraft {
  final int diaSemana; // 0 = Lunes, 6 = Domingo
  final bool open;
  final TimeOfDay from1;
  final TimeOfDay to1;
  final bool hasBreak;
  final TimeOfDay from2;
  final TimeOfDay to2;

  const DayDraft({
    required this.diaSemana,
    required this.open,
    this.from1 = const TimeOfDay(hour: 9, minute: 0),
    this.to1 = const TimeOfDay(hour: 13, minute: 0),
    this.hasBreak = false,
    this.from2 = const TimeOfDay(hour: 15, minute: 0),
    this.to2 = const TimeOfDay(hour: 19, minute: 0),
  });

  DayDraft copyWith({
    bool? open,
    TimeOfDay? from1,
    TimeOfDay? to1,
    bool? hasBreak,
    TimeOfDay? from2,
    TimeOfDay? to2,
  }) =>
      DayDraft(
        diaSemana: diaSemana,
        open: open ?? this.open,
        from1: from1 ?? this.from1,
        to1: to1 ?? this.to1,
        hasBreak: hasBreak ?? this.hasBreak,
        from2: from2 ?? this.from2,
        to2: to2 ?? this.to2,
      );

  @override
  bool operator ==(Object other) =>
      other is DayDraft &&
      other.diaSemana == diaSemana &&
      other.open == open &&
      other.from1 == from1 &&
      other.to1 == to1 &&
      other.hasBreak == hasBreak &&
      other.from2 == from2 &&
      other.to2 == to2;

  @override
  int get hashCode => Object.hash(
        diaSemana, open, from1, to1, hasBreak, from2, to2);
}

enum ExcType { closed, modifiedHours, vacation, openDay }

class ExceptionDraft {
  final String id;
  final ExcType type;
  final DateTime dateFrom;
  final DateTime dateTo;
  final TimeOfDay? from1;
  final TimeOfDay? to1;
  final bool hasBreak;
  final TimeOfDay? from2;
  final TimeOfDay? to2;
  final String? reason;

  const ExceptionDraft({
    required this.id,
    required this.type,
    required this.dateFrom,
    required this.dateTo,
    this.from1,
    this.to1,
    this.hasBreak = false,
    this.from2,
    this.to2,
    this.reason,
  });

  ExceptionDraft copyWith({
    ExcType? type,
    DateTime? dateFrom,
    DateTime? dateTo,
    TimeOfDay? from1,
    TimeOfDay? to1,
    bool? hasBreak,
    TimeOfDay? from2,
    TimeOfDay? to2,
    String? reason,
  }) =>
      ExceptionDraft(
        id: id,
        type: type ?? this.type,
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: dateTo ?? this.dateTo,
        from1: from1 ?? this.from1,
        to1: to1 ?? this.to1,
        hasBreak: hasBreak ?? this.hasBreak,
        from2: from2 ?? this.from2,
        to2: to2 ?? this.to2,
        reason: reason ?? this.reason,
      );
}

class BookingRulesDraft {
  final bool byService;
  final int fixedSlotMin;
  final int bufferMin;
  final int minLeadHours;
  final int maxLeadDays;

  const BookingRulesDraft({
    this.byService = true,
    this.fixedSlotMin = 30,
    this.bufferMin = 10,
    this.minLeadHours = 2,
    this.maxLeadDays = 60,
  });

  BookingRulesDraft copyWith({
    bool? byService,
    int? fixedSlotMin,
    int? bufferMin,
    int? minLeadHours,
    int? maxLeadDays,
  }) =>
      BookingRulesDraft(
        byService: byService ?? this.byService,
        fixedSlotMin: fixedSlotMin ?? this.fixedSlotMin,
        bufferMin: bufferMin ?? this.bufferMin,
        minLeadHours: minLeadHours ?? this.minLeadHours,
        maxLeadDays: maxLeadDays ?? this.maxLeadDays,
      );

  @override
  bool operator ==(Object other) =>
      other is BookingRulesDraft &&
      other.byService == byService &&
      other.fixedSlotMin == fixedSlotMin &&
      other.bufferMin == bufferMin &&
      other.minLeadHours == minLeadHours &&
      other.maxLeadDays == maxLeadDays;

  @override
  int get hashCode =>
      Object.hash(byService, fixedSlotMin, bufferMin, minLeadHours, maxLeadDays);
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class HorariosState {
  final List<DayDraft> days;
  final List<ExceptionDraft> exceptions;
  final BookingRulesDraft rules;
  final List<DayDraft> savedDays;
  final List<ExceptionDraft> savedExceptions;
  final BookingRulesDraft savedRules;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const HorariosState({
    this.days = const [],
    this.exceptions = const [],
    this.rules = const BookingRulesDraft(),
    this.savedDays = const [],
    this.savedExceptions = const [],
    this.savedRules = const BookingRulesDraft(),
    this.isLoading = true,
    this.isSaving = false,
    this.error,
  });

  bool get hasChanges {
    if (days.length != savedDays.length) return true;
    for (var i = 0; i < days.length; i++) {
      if (days[i] != savedDays[i]) return true;
    }
    if (rules != savedRules) return true;
    if (exceptions.length != savedExceptions.length) return true;
    return false;
  }

  HorariosState copyWith({
    List<DayDraft>? days,
    List<ExceptionDraft>? exceptions,
    BookingRulesDraft? rules,
    List<DayDraft>? savedDays,
    List<ExceptionDraft>? savedExceptions,
    BookingRulesDraft? savedRules,
    bool? isLoading,
    bool? isSaving,
    Object? error = _sentinel,
  }) =>
      HorariosState(
        days: days ?? this.days,
        exceptions: exceptions ?? this.exceptions,
        rules: rules ?? this.rules,
        savedDays: savedDays ?? this.savedDays,
        savedExceptions: savedExceptions ?? this.savedExceptions,
        savedRules: savedRules ?? this.savedRules,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );

  static const _sentinel = Object();
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

TimeOfDay _parseTime(String? s, TimeOfDay fallback) {
  if (s == null || s.isEmpty) return fallback;
  final parts = s.split(':');
  if (parts.length < 2) return fallback;
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? fallback.hour,
    minute: int.tryParse(parts[1]) ?? fallback.minute,
  );
}

String _fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

List<DayDraft> _daysFromHours(List<BusinessHours> hours) {
  // Group by diaSemana to support 2-range days (one entry per range).
  final grouped = <int, List<BusinessHours>>{};
  for (final h in hours) {
    grouped.putIfAbsent(h.diaSemana, () => []).add(h);
  }
  return List.generate(7, (i) {
    final entries = grouped[i];
    if (entries == null || entries.isEmpty || entries.every((e) => e.cerrado)) {
      return DayDraft(
        diaSemana: i,
        open: false,
        from1: const TimeOfDay(hour: 9, minute: 0),
        to1: const TimeOfDay(hour: 13, minute: 0),
        from2: const TimeOfDay(hour: 15, minute: 0),
        to2: const TimeOfDay(hour: 19, minute: 0),
      );
    }
    // Use the first (or only) entry for the day.
    final h = entries.first;
    final from1 =
        _parseTime(h.apertura, const TimeOfDay(hour: 9, minute: 0));
    final to1 =
        _parseTime(h.cierre, const TimeOfDay(hour: 13, minute: 0));
    if (h.apertura2 != null && h.cierre2 != null) {
      final from2 =
          _parseTime(h.apertura2, const TimeOfDay(hour: 15, minute: 0));
      final to2 =
          _parseTime(h.cierre2, const TimeOfDay(hour: 19, minute: 0));
      return DayDraft(
        diaSemana: i,
        open: true,
        from1: from1,
        to1: to1,
        hasBreak: true,
        from2: from2,
        to2: to2,
      );
    }
    return DayDraft(
      diaSemana: i,
      open: true,
      from1: from1,
      to1: to1,
    );
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class HorariosNotifier
    extends StateNotifier<HorariosState> {
  HorariosNotifier(this._ref, this._key)
      : super(const HorariosState(isLoading: true)) {
    _init();
  }

  final Ref _ref;
  final ({String tenantId, String businessId}) _key;

  void _init() {
    final hoursState = _ref.read(businessHoursProvider(_key));
    if (!hoursState.isLoading && hoursState.error == null) {
      _loadFromHours(hoursState.hours);
    } else {
      // Wait for provider to load
      _ref.listen<BusinessHoursState>(businessHoursProvider(_key), (_, next) {
        if (!next.isLoading && next.error == null && state.isLoading) {
          _loadFromHours(next.hours);
        }
        if (next.error != null && state.isLoading) {
          state = state.copyWith(isLoading: false, error: next.error);
        }
      });
    }
  }

  void _loadFromHours(List<BusinessHours> hours) {
    final days = _daysFromHours(hours);
    state = state.copyWith(
      days: days,
      savedDays: List.from(days),
      isLoading: false,
      error: null,
    );
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  void toggleDay(int diaSemana) {
    final updated = state.days.map((d) {
      if (d.diaSemana == diaSemana) return d.copyWith(open: !d.open);
      return d;
    }).toList();
    state = state.copyWith(days: updated);
  }

  void updateFrom1(int diaSemana, TimeOfDay t) => _updateDay(
        diaSemana,
        (d) => d.copyWith(from1: t),
      );

  void updateTo1(int diaSemana, TimeOfDay t) => _updateDay(
        diaSemana,
        (d) => d.copyWith(to1: t),
      );

  void updateFrom2(int diaSemana, TimeOfDay t) => _updateDay(
        diaSemana,
        (d) => d.copyWith(from2: t),
      );

  void updateTo2(int diaSemana, TimeOfDay t) => _updateDay(
        diaSemana,
        (d) => d.copyWith(to2: t),
      );

  void addBreak(int diaSemana) => _updateDay(
        diaSemana,
        (d) => d.copyWith(hasBreak: true),
      );

  void removeBreak(int diaSemana) => _updateDay(
        diaSemana,
        (d) => d.copyWith(hasBreak: false),
      );

  void _updateDay(int diaSemana, DayDraft Function(DayDraft) fn) {
    final updated = state.days
        .map((d) => d.diaSemana == diaSemana ? fn(d) : d)
        .toList();
    state = state.copyWith(days: updated);
  }

  void copyDayTo(int source, List<int> targets) {
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
    state = state.copyWith(days: updated);
  }

  void updateRules(BookingRulesDraft rules) {
    state = state.copyWith(rules: rules);
  }

  void addException(ExceptionDraft e) {
    state = state.copyWith(exceptions: [...state.exceptions, e]);
  }

  void removeException(String id) {
    state = state.copyWith(
      exceptions: state.exceptions.where((e) => e.id != id).toList(),
    );
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true, error: null);
    // One entry per day; breaks use apertura2/cierre2.
    final hours = state.days.map((d) {
      if (!d.open) {
        return BusinessHours(
          id: '',
          businessId: _key.businessId,
          diaSemana: d.diaSemana,
          cerrado: true,
        );
      }
      return BusinessHours(
        id: '',
        businessId: _key.businessId,
        diaSemana: d.diaSemana,
        apertura: _fmtTime(d.from1),
        cierre: _fmtTime(d.to1),
        apertura2: d.hasBreak ? _fmtTime(d.from2) : null,
        cierre2: d.hasBreak ? _fmtTime(d.to2) : null,
        cerrado: false,
      );
    }).toList();

    final ok = await _ref
        .read(businessHoursProvider(_key).notifier)
        .save(hours);

    if (ok) {
      state = state.copyWith(
        isSaving: false,
        savedDays: List.from(state.days),
        savedExceptions: List.from(state.exceptions),
        savedRules: state.rules,
      );
    } else {
      final err = _ref.read(businessHoursProvider(_key)).error;
      state = state.copyWith(
        isSaving: false,
        error: err ?? 'Error al guardar',
      );
    }
  }

  void revert() {
    state = state.copyWith(
      days: List.from(state.savedDays),
      exceptions: List.from(state.savedExceptions),
      rules: state.savedRules,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final horariosControllerProvider = StateNotifierProvider.family<
    HorariosNotifier,
    HorariosState,
    ({String tenantId, String businessId})>((ref, key) {
  return HorariosNotifier(ref, key);
});
