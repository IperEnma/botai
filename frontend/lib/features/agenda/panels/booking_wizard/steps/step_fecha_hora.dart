import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:botai_admin/features/agenda/register/konecta_tokens.dart';
import 'package:botai_admin/models/agenda/booking.dart';
import 'package:botai_admin/models/agenda/staff_member.dart';
import 'package:botai_admin/providers/agenda/tenant/business_hours_provider.dart';
import 'package:botai_admin/providers/agenda/tenant/agenda_week_provider.dart';
import 'package:botai_admin/providers/agenda/tenant/business_staff_provider.dart';
import 'package:botai_admin/features/agenda/tenant/tabs/horarios/utils/slot_generator.dart';
import 'package:botai_admin/providers/agenda/tenant/horarios_controller_provider.dart';
import '../booking_wizard_controller.dart';

class StepFechaHora extends ConsumerStatefulWidget {
  const StepFechaHora({
    super.key,
    required this.controller,
    required this.tenantId,
    required this.businessId,
  });

  final BookingWizardController controller;
  final String tenantId;
  final String businessId;

  @override
  ConsumerState<StepFechaHora> createState() => _StepFechaHoraState();
}

class _StepFechaHoraState extends ConsumerState<StepFechaHora> {
  late DateTime _displayMonth;
  final _notasCtrl = TextEditingController();

  static const _monthNames = [
    '',
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _dayAbbrs = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  static const _weekDayHeaders = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];

  @override
  void initState() {
    super.initState();
    final initial = widget.controller.draft.date ?? DateTime.now();
    _displayMonth = DateTime(initial.year, initial.month);
    _notasCtrl.text = widget.controller.draft.notes;
    _notasCtrl.addListener(() {
      widget.controller.setNotes(_notasCtrl.text);
    });
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? get _selectedTime => widget.controller.draft.time;

  /// weekday mapping: DateTime.weekday (1=Mon, 7=Sun) → grid column 0=Sun..6=Sat
  int _calWeekday(DateTime d) => d.weekday % 7;

  /// BusinessHours.diaSemana: 0=Lun, 6=Dom
  int _bHoursDiaSemana(DateTime d) => (d.weekday - 1) % 7;

  @override
  Widget build(BuildContext context) {
    final hoursState = ref.watch(
      businessHoursProvider(
        (tenantId: widget.tenantId, businessId: widget.businessId),
      ),
    );

    final staffState = ref.watch(
      businessStaffProvider((tenantId: widget.tenantId, businessId: widget.businessId)),
    );

    final draft = widget.controller.draft;
    final proId = draft.effectiveStaffMemberId;
    final selectedStaff = proId == null
        ? null
        : staffState.members.where((s) => s.id == proId).firstOrNull;

    // Build a day-availability override map from the staff's custom schedule
    Map<int, bool>? staffWorkDays;
    if (selectedStaff?.customSchedule != null) {
      const keys = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
      staffWorkDays = {};
      for (var i = 0; i < keys.length; i++) {
        final day = selectedStaff!.customSchedule![keys[i]] as Map<String, dynamic>?;
        staffWorkDays[i] = day?['open'] == true;
      }
    }

    final proName = !draft.requiresStaffStep
        ? 'el negocio'
        : draft.anyProfessional
            ? 'cualquier profesional'
            : (selectedStaff?.nombre ?? 'el profesional');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cuándo?',
            style: KTokens.tHero,
          ),
          const SizedBox(height: 6),
          Text(
            'El calendario muestra solo los días que $proName trabaja.',
            style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
          ),
          const SizedBox(height: 18),
          // Calendar card
          _CalendarCard(
            displayMonth: _displayMonth,
            selectedDate: widget.controller.draft.date,
            hoursState: hoursState,
            staffWorkDays: staffWorkDays,
            onPrev: () => setState(
              () => _displayMonth = DateTime(
                _displayMonth.year,
                _displayMonth.month - 1,
              ),
            ),
            onNext: () => setState(
              () => _displayMonth = DateTime(
                _displayMonth.year,
                _displayMonth.month + 1,
              ),
            ),
            onSelectDate: (d) => widget.controller.setDate(d),
            calWeekday: _calWeekday,
            bHoursDiaSemana: _bHoursDiaSemana,
            monthNames: _monthNames,
            weekDayHeaders: _weekDayHeaders,
            dayAbbrs: _dayAbbrs,
            proName: proName,
          ),
          // Slots
          if (widget.controller.draft.date != null) ...[
            const SizedBox(height: 16),
            _SlotsSection(
              controller: widget.controller,
              businessId: widget.businessId,
              hoursState: hoursState,
              selectedDate: widget.controller.draft.date!,
              selectedTime: _selectedTime,
              dayAbbrs: _dayAbbrs,
              selectedStaff: selectedStaff,
            ),
          ],
          // WhatsApp + Notes
          if (widget.controller.draft.date != null &&
              _selectedTime != null) ...[
            const SizedBox(height: 16),
            _WhatsAppToggle(
              sendWhatsApp: widget.controller.draft.sendWhatsApp,
              telefono: widget.controller.draft.cliente?.telefono,
              onChanged: widget.controller.setSendWhatsApp,
            ),
            const SizedBox(height: 12),
            _NotesField(controller: _notasCtrl),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calendar Card
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.displayMonth,
    required this.selectedDate,
    required this.hoursState,
    this.staffWorkDays,
    required this.onPrev,
    required this.onNext,
    required this.onSelectDate,
    required this.calWeekday,
    required this.bHoursDiaSemana,
    required this.monthNames,
    required this.weekDayHeaders,
    required this.dayAbbrs,
    required this.proName,
  });

  final DateTime displayMonth;
  final DateTime? selectedDate;
  final BusinessHoursState hoursState;
  /// When non-null, overrides business hours: maps diaSemana (0=lun..6=dom) → isOpen.
  final Map<int, bool>? staffWorkDays;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime) onSelectDate;
  final int Function(DateTime) calWeekday;
  final int Function(DateTime) bHoursDiaSemana;
  final List<String> monthNames;
  final List<String> weekDayHeaders;
  final List<String> dayAbbrs;
  final String proName;

  bool _isWorkDay(DateTime d) {
    final dia = bHoursDiaSemana(d);
    // Business hours are the hard ceiling — closed days are never available.
    if (!hoursState.isLoading && hoursState.hours.isNotEmpty) {
      final bh = hoursState.hours.where((h) => h.diaSemana == dia).firstOrNull;
      if (bh != null && bh.cerrado) return false;
    }
    if (staffWorkDays != null) return staffWorkDays![dia] ?? false;
    if (hoursState.isLoading || hoursState.hours.isEmpty) return true;
    final h = hoursState.hours.where((h) => h.diaSemana == dia).firstOrNull;
    return h != null && !h.cerrado;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final startOffset = calWeekday(firstOfMonth);

    final cells = <Widget>[];
    for (var i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(displayMonth.year, displayMonth.month, d);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isSelected = selectedDate != null &&
          date.year == selectedDate!.year &&
          date.month == selectedDate!.month &&
          date.day == selectedDate!.day;
      final isWork = _isWorkDay(date);
      final isPast =
          date.isBefore(DateTime(today.year, today.month, today.day));

      cells.add(
        _DayCell(
          day: d,
          isToday: isToday,
          isSelected: isSelected,
          isAvailable: isWork && !isPast,
          onTap: (isWork && !isPast) ? () => onSelectDate(date) : null,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KTokens.rMd),
        border: Border.all(color: KTokens.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${monthNames[displayMonth.month]} ${displayMonth.year}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KTokens.ink,
                ),
              ),
              const Spacer(),
              _NavBtn(label: '‹', onTap: onPrev),
              const SizedBox(width: 4),
              _NavBtn(label: '›', onTap: onNext),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: weekDayHeaders.map((h) {
              return Expanded(
                child: Center(
                  child: Text(
                    h,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: KTokens.inkSoft,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            children: cells,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Divider(height: 1, color: KTokens.border),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: KTokens.excOpen,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$proName disponible',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: KTokens.inkSoft,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x08000000),
                  border: Border.all(color: const Color(0xFFD4D2CB)),
                ),
                child: Center(
                  child: Text(
                    '00',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      color: const Color(0xFFD4D2CB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                ' No trabaja',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: const Color(0xFFD4D2CB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: KTokens.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: KTokens.ink),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isAvailable,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = const Color(0xFFD4D2CB);
    FontWeight fontWeight = FontWeight.w400;

    if (isSelected) {
      bgColor = KTokens.accent;
      textColor = Colors.white;
      fontWeight = FontWeight.w600;
    } else if (isAvailable && isToday) {
      bgColor = KTokens.accentSoft;
      textColor = KTokens.ink;
      fontWeight = FontWeight.w500;
    } else if (isAvailable) {
      textColor = KTokens.ink;
      fontWeight = FontWeight.w500;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
            if (isAvailable && !isSelected)
              Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: KTokens.excOpen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slots Section
// ─────────────────────────────────────────────────────────────────────────────

class _SlotsSection extends ConsumerWidget {
  const _SlotsSection({
    required this.controller,
    required this.businessId,
    required this.hoursState,
    required this.selectedDate,
    required this.selectedTime,
    required this.dayAbbrs,
    this.selectedStaff,
  });

  final BookingWizardController controller;
  final String businessId;
  final BusinessHoursState hoursState;
  final DateTime selectedDate;
  final TimeOfDay? selectedTime;
  final List<String> dayAbbrs;
  final StaffMember? selectedStaff;

  int _bHoursDiaSemana(DateTime d) => (d.weekday - 1) % 7;

  DateTime _firstDayOfSunWeek(DateTime d) {
    return d.subtract(Duration(days: d.weekday % 7));
  }

  TimeOfDay _parseTimeStr(String? s, TimeOfDay fallback) {
    if (s == null || s.isEmpty) return fallback;
    final parts = s.split(':');
    if (parts.length < 2) return fallback;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? fallback.hour,
      minute: int.tryParse(parts[1]) ?? fallback.minute,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durMin = controller.draft.servicio?.duracionMin ?? 30;
    final proId = controller.draft.effectiveStaffMemberId;

    final dia = _bHoursDiaSemana(selectedDate);

    DayDraft dayDraft;
    final cs = selectedStaff?.customSchedule;
    final hourEntry =
        hoursState.hours.where((h) => h.diaSemana == dia).firstOrNull;
    final bizClosed = hourEntry != null && hourEntry.cerrado;

    if (bizClosed) {
      // Business is closed on this day — no slots regardless of staff schedule.
      dayDraft = DayDraft(diaSemana: dia, open: false);
    } else if (cs != null) {
      // Staff has a custom schedule that is already clamped to business hours
      // by the backend sanitizer — use it directly.
      const dayKeys = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
      final dayEntry = cs[dayKeys[dia]] as Map<String, dynamic>?;
      if (dayEntry == null || dayEntry['open'] != true) {
        dayDraft = DayDraft(diaSemana: dia, open: false);
      } else {
        final from1 = _parseTimeStr(dayEntry['from'] as String?, const TimeOfDay(hour: 9, minute: 0));
        final to1   = _parseTimeStr(dayEntry['to']   as String?, const TimeOfDay(hour: 18, minute: 0));
        dayDraft = DayDraft(diaSemana: dia, open: true, from1: from1, to1: to1);
      }
    } else {
      if (hourEntry == null) {
        dayDraft = DayDraft(diaSemana: dia, open: false);
      } else {
        final from1 = _parseTimeStr(
            hourEntry.apertura, const TimeOfDay(hour: 9, minute: 0));
        final to1 = _parseTimeStr(
            hourEntry.cierre, const TimeOfDay(hour: 18, minute: 0));
        final hasBreak =
            hourEntry.apertura2 != null && hourEntry.cierre2 != null;
        final from2 = _parseTimeStr(
            hourEntry.apertura2, const TimeOfDay(hour: 15, minute: 0));
        final to2 = _parseTimeStr(
            hourEntry.cierre2, const TimeOfDay(hour: 19, minute: 0));
        dayDraft = DayDraft(
          diaSemana: dia,
          open: true,
          from1: from1,
          to1: to1,
          hasBreak: hasBreak,
          from2: from2,
          to2: to2,
        );
      }
    }

    final rules = BookingRulesDraft(
      byService: true,
      fixedSlotMin: durMin,
      bufferMin: 10,
    );
    final slotsResult = generateSlots(
      day: dayDraft,
      rules: rules,
      serviceDurationMin: durMin,
    );

    final weekStart = _firstDayOfSunWeek(selectedDate);
    final weekKey = (businessId: businessId, weekStart: weekStart);
    final bookingsAsync = ref.watch(agendaWeekBookingsProvider(weekKey));

    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final allSlots = isToday
        ? slotsResult.all.where((s) {
            final slotMin = s.time.hour * 60 + s.time.minute;
            final nowMin = now.hour * 60 + now.minute;
            return slotMin > nowMin;
          }).toList()
        : slotsResult.all;

    if (allSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KTokens.bg,
          borderRadius: BorderRadius.circular(KTokens.rMd),
          border: Border.all(color: KTokens.border),
        ),
        child: Text(
          'Sin turnos disponibles para este día',
          style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
        ),
      );
    }

    return bookingsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, st) => _SlotsGrid(
        slots: allSlots,
        occupiedSlots: const [],
        selectedTime: selectedTime,
        durMin: durMin,
        onSelect: (t) => controller.setDateTime(selectedDate, t),
        selectedDate: selectedDate,
        dayAbbrs: dayAbbrs,
      ),
      data: (bookings) {
        final dayBookings = bookings.where((b) {
          final sameDay = b.fechaHoraInicio.year == selectedDate.year &&
              b.fechaHoraInicio.month == selectedDate.month &&
              b.fechaHoraInicio.day == selectedDate.day;
          final sameProf = proId == null || b.staffMemberId == proId;
          return sameDay && sameProf;
        }).toList();

        return _SlotsGrid(
          slots: allSlots,
          occupiedSlots: dayBookings,
          selectedTime: selectedTime,
          durMin: durMin,
          onSelect: (t) => controller.setDateTime(selectedDate, t),
          selectedDate: selectedDate,
          dayAbbrs: dayAbbrs,
        );
      },
    );
  }
}

class _SlotsGrid extends StatelessWidget {
  const _SlotsGrid({
    required this.slots,
    required this.occupiedSlots,
    required this.selectedTime,
    required this.durMin,
    required this.onSelect,
    required this.selectedDate,
    required this.dayAbbrs,
  });

  final List<SlotPreview> slots;
  final List<Booking> occupiedSlots;
  final TimeOfDay? selectedTime;
  final int durMin;
  final void Function(TimeOfDay) onSelect;
  final DateTime selectedDate;
  final List<String> dayAbbrs;

  bool _isOccupied(SlotPreview slot) {
    final slotStart = slot.time.hour * 60 + slot.time.minute;
    final slotEnd = slotStart + durMin;
    for (final b in occupiedSlots) {
      final bStart =
          b.fechaHoraInicio.hour * 60 + b.fechaHoraInicio.minute;
      final bEnd = b.fechaHoraFin.hour * 60 + b.fechaHoraFin.minute;
      if (slotStart < bEnd && slotEnd > bStart) return true;
    }
    return false;
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final morning = slots.where((s) => s.time.hour < 13).toList();
    final afternoon =
        slots.where((s) => s.time.hour >= 13 && s.time.hour < 20).toList();
    final night = slots.where((s) => s.time.hour >= 20).toList();

    final dayAbbr = dayAbbrs[selectedDate.weekday % 7];
    final headerText =
        'HORARIOS LIBRES · $dayAbbr ${selectedDate.day} · DURACIÓN $durMin MIN';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headerText,
          style: GoogleFonts.jetBrainsMono(fontSize: 9, color: KTokens.inkSoft),
        ),
        const SizedBox(height: 10),
        if (morning.isNotEmpty) ...[
          _SlotGroup(
            icon: '☀',
            label: 'MAÑANA',
            freeCount: morning.where((s) => !_isOccupied(s)).length,
            slots: morning,
            isOccupied: _isOccupied,
            selectedTime: selectedTime,
            onSelect: onSelect,
            fmt: _fmt,
          ),
          const SizedBox(height: 10),
        ],
        if (afternoon.isNotEmpty) ...[
          _SlotGroup(
            icon: '◐',
            label: 'TARDE',
            freeCount: afternoon.where((s) => !_isOccupied(s)).length,
            slots: afternoon,
            isOccupied: _isOccupied,
            selectedTime: selectedTime,
            onSelect: onSelect,
            fmt: _fmt,
          ),
          const SizedBox(height: 10),
        ],
        if (night.isNotEmpty)
          _SlotGroup(
            icon: '🌙',
            label: 'NOCHE',
            freeCount: night.where((s) => !_isOccupied(s)).length,
            slots: night,
            isOccupied: _isOccupied,
            selectedTime: selectedTime,
            onSelect: onSelect,
            fmt: _fmt,
          ),
      ],
    );
  }
}

class _SlotGroup extends StatelessWidget {
  const _SlotGroup({
    required this.icon,
    required this.label,
    required this.freeCount,
    required this.slots,
    required this.isOccupied,
    required this.selectedTime,
    required this.onSelect,
    required this.fmt,
  });

  final String icon;
  final String label;
  final int freeCount;
  final List<SlotPreview> slots;
  final bool Function(SlotPreview) isOccupied;
  final TimeOfDay? selectedTime;
  final void Function(TimeOfDay) onSelect;
  final String Function(TimeOfDay) fmt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$icon $label',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: KTokens.inkSoft,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$freeCount LIBRES',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: KTokens.excOpen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: slots.map((s) {
            final occupied = isOccupied(s);
            final selTime = selectedTime;
            final isSelected = !occupied &&
                selTime != null &&
                selTime.hour == s.time.hour &&
                selTime.minute == s.time.minute;
            final timeStr = fmt(s.time);

            return Semantics(
              label: '$timeStr, ${occupied ? 'ocupado' : 'disponible'}',
              child: GestureDetector(
                onTap: occupied ? null : () => onSelect(s.time),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? KTokens.accent
                        : occupied
                            ? const Color(0x08000000)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: occupied
                                ? Colors.transparent
                                : KTokens.border,
                          ),
                  ),
                  child: Center(
                    child: Text(
                      timeStr,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : occupied
                                ? const Color(0xFFCDCAC3)
                                : KTokens.ink,
                        decoration:
                            occupied ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WhatsApp Toggle
// ─────────────────────────────────────────────────────────────────────────────

class _WhatsAppToggle extends StatelessWidget {
  const _WhatsAppToggle({
    required this.sendWhatsApp,
    required this.telefono,
    required this.onChanged,
  });

  final bool sendWhatsApp;
  final String? telefono;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KTokens.rMd),
        border: Border.all(color: KTokens.border),
      ),
      child: Row(
        children: [
          Switch(
            value: sendWhatsApp,
            onChanged: onChanged,
            activeThumbColor: KTokens.accent,
            activeTrackColor: KTokens.accentSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enviar confirmación por WhatsApp',
                  style: GoogleFonts.inter(fontSize: 13, color: KTokens.ink),
                ),
                if (telefono != null)
                  Text(
                    telefono!,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: KTokens.inkSoft,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notes Field
// ─────────────────────────────────────────────────────────────────────────────

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      maxLength: 200,
      style: GoogleFonts.inter(fontSize: 13, color: KTokens.ink),
      decoration: InputDecoration(
        hintText: 'Cualquier dato extra para el turno…',
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: KTokens.inkPlaceholder,
        ),
        filled: true,
        fillColor: KTokens.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KTokens.rMd),
          borderSide: BorderSide(color: KTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KTokens.rMd),
          borderSide: BorderSide(color: KTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KTokens.rMd),
          borderSide: const BorderSide(color: KTokens.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
