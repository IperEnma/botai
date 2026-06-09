import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/availability_slot.dart';
import '../../../models/agenda/business_hours.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import 'public_booking_hours.dart';
import 'public_reservar_layout.dart';

/// Paso unificado: filtro de profesional + calendario mensual + horarios del día.
class PublicReservarScheduleStep extends ConsumerStatefulWidget {
  const PublicReservarScheduleStep({
    super.key,
    required this.theme,
    required this.slug,
    required this.service,
    required this.anyStaff,
    required this.selectedStaff,
    required this.selectedDate,
    required this.selectedSlot,
    required this.onAnyStaffChanged,
    required this.onStaffChanged,
    required this.onDateChanged,
    required this.onSlotChanged,
  });

  final PublicReservarTheme theme;
  final String slug;
  final AgendaService service;
  final bool anyStaff;
  final StaffMember? selectedStaff;
  final DateTime? selectedDate;
  final AvailabilitySlot? selectedSlot;
  final VoidCallback onAnyStaffChanged;
  final ValueChanged<StaffMember> onStaffChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<AvailabilitySlot?> onSlotChanged;

  @override
  ConsumerState<PublicReservarScheduleStep> createState() =>
      _PublicReservarScheduleStepState();
}

class _PublicReservarScheduleStepState
    extends ConsumerState<PublicReservarScheduleStep> {
  late DateTime _visibleMonth;
  Map<String, bool> _dayHasSlots = {};
  bool _loadingMonth = true;
  int _monthLoadToken = 0;
  Future<List<AvailabilitySlot>>? _slotsFuture;
  String? _availabilityKey;
  final GlobalKey _slotsSectionKey = GlobalKey();

  bool get _usesStaff => widget.service.requiresStaffSelection;

  String? get _effectiveStaffId {
    if (!_usesStaff) return null;
    return widget.anyStaff ? null : widget.selectedStaff?.id;
  }

  @override
  void initState() {
    super.initState();
    final base = widget.selectedDate ?? DateTime.now();
    _visibleMonth = DateTime(base.year, base.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadMonth());
  }

  @override
  void didUpdateWidget(PublicReservarScheduleStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    final staffChanged = oldWidget.anyStaff != widget.anyStaff ||
        oldWidget.selectedStaff?.id != widget.selectedStaff?.id;
    final serviceChanged = oldWidget.service.id != widget.service.id;
    if (staffChanged || serviceChanged) {
      _reloadMonth();
      _reloadSlotsForSelectedDate();
    }
    if (widget.selectedDate != oldWidget.selectedDate) {
      _reloadSlotsForSelectedDate();
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _scheduleScrollToSlotsSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Segundo frame: el FutureBuilder ya midió loading o chips de hora.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = _slotsSectionKey.currentContext;
        if (target == null) return;
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      });
    });
  }

  void _reloadSlotsForSelectedDate() {
    final date = widget.selectedDate;
    if (date == null) {
      setState(() {
        _slotsFuture = null;
        _availabilityKey = null;
      });
      return;
    }
    final key = (
      slug: widget.slug,
      serviceId: widget.service.id,
      staffMemberId: _effectiveStaffId,
      date: _dateKey(date),
    );
    if (_availabilityKey == '${key.slug}|${key.serviceId}|${key.staffMemberId}|${key.date}') {
      return;
    }
    setState(() {
      _availabilityKey =
          '${key.slug}|${key.serviceId}|${key.staffMemberId}|${key.date}';
      _slotsFuture = ref.read(availabilityBySlugProvider(key).future);
    });
    _scheduleScrollToSlotsSection();
    _slotsFuture!.whenComplete(() {
      if (mounted) _scheduleScrollToSlotsSection();
    });
  }

  Future<void> _reloadMonth() async {
    if (!mounted) return;
    final token = ++_monthLoadToken;
    setState(() {
      _loadingMonth = true;
      _dayHasSlots = {};
    });

    final hours = await ref.read(publicHoursBySlugProvider(widget.slug).future);
    if (!mounted || token != _monthLoadToken) return;

    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final last = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final api = ref.read(agendaApiServiceProvider);
    final map = <String, bool>{};
    final futures = <Future<void>>[];

    for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
      final day = DateTime(d.year, d.month, d.day);
      if (day.isBefore(todayDate)) continue;
      if (!isPublicBookingDayOpen(day, hours)) continue;
      final dateStr = _dateKey(day);
      futures.add(
        api
            .publicAvailabilityBySlug(
              slug: widget.slug,
              serviceId: widget.service.id,
              staffMemberId: _effectiveStaffId,
              date: dateStr,
            )
            .then((slots) => map[dateStr] = slots.isNotEmpty)
            .catchError((_) => map[dateStr] = false),
      );
    }

    await Future.wait(futures);
    if (!mounted || token != _monthLoadToken) return;
    setState(() {
      _dayHasSlots = map;
      _loadingMonth = false;
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _loadingMonth = true;
      _dayHasSlots = {};
    });
    _reloadMonth();
  }

  void _onStaffFilterAny() {
    widget.onAnyStaffChanged();
    widget.onSlotChanged(null);
  }

  void _onStaffFilterMember(StaffMember m) {
    widget.onStaffChanged(m);
    widget.onSlotChanged(null);
  }

  void _onDayTap(DateTime day, {required bool enabled}) {
    if (!enabled) return;
    widget.onDateChanged(day);
    widget.onSlotChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_usesStaff) ...[
          _StaffFilterRow(
            theme: t,
            slug: widget.slug,
            serviceId: widget.service.id,
            anyStaff: widget.anyStaff,
            selectedStaff: widget.selectedStaff,
            onAny: _onStaffFilterAny,
            onStaff: _onStaffFilterMember,
          ),
          const SizedBox(height: 20),
        ],
        _MonthCalendar(
          theme: t,
          visibleMonth: _visibleMonth,
          selectedDate: widget.selectedDate,
          dayHasSlots: _dayHasSlots,
          loading: _loadingMonth ||
              ref.watch(publicHoursBySlugProvider(widget.slug)).isLoading,
          hoursAsync: ref.watch(publicHoursBySlugProvider(widget.slug)),
          onPrevMonth: () => _shiftMonth(-1),
          onNextMonth: () => _shiftMonth(1),
          onDayTap: _onDayTap,
        ),
        if (widget.selectedDate != null) ...[
          const SizedBox(height: 24),
          KeyedSubtree(
            key: _slotsSectionKey,
            child: _DaySlotsSection(
              theme: t,
              date: widget.selectedDate!,
              slotsFuture: _slotsFuture,
              selected: widget.selectedSlot,
              onSelect: widget.onSlotChanged,
            ),
          ),
        ],
      ],
    );
  }
}

class _StaffFilterRow extends ConsumerWidget {
  const _StaffFilterRow({
    required this.theme,
    required this.slug,
    required this.serviceId,
    required this.anyStaff,
    required this.selectedStaff,
    required this.onAny,
    required this.onStaff,
  });

  final PublicReservarTheme theme;
  final String slug;
  final String serviceId;
  final bool anyStaff;
  final StaffMember? selectedStaff;
  final VoidCallback onAny;
  final ValueChanged<StaffMember> onStaff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = theme;
    final staffAsync = ref.watch(publicStaffBySlugProvider(slug));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profesional',
          style: t.textStyle(size: 13, weight: FontWeight.w600, color: t.textSub),
        ),
        const SizedBox(height: 10),
        staffAsync.when(
          loading: () => const SizedBox(
            height: 36,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => Text(
            'No se pudo cargar el equipo.',
            style: t.textStyle(size: 13, color: t.textSub),
          ),
          data: (allStaff) {
            final staff = allStaff
                .where((m) =>
                    m.activo &&
                    (m.serviceIds.isEmpty || m.serviceIds.contains(serviceId)))
                .toList();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    theme: t,
                    label: 'Cualquiera',
                    icon: Icons.groups_outlined,
                    selected: anyStaff,
                    onTap: onAny,
                  ),
                  const SizedBox(width: 8),
                  for (final m in staff)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        theme: t,
                        label: m.nombre.split(' ').first,
                        selected: !anyStaff && selectedStaff?.id == m.id,
                        onTap: () => onStaff(m),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final PublicReservarTheme theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? t.primary : t.cardFill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? t.primary : t.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : t.textSub),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: t.textStyle(
                size: 13,
                weight: FontWeight.w600,
                color: selected ? Colors.white : t.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.theme,
    required this.visibleMonth,
    required this.selectedDate,
    required this.dayHasSlots,
    required this.loading,
    required this.hoursAsync,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDayTap,
  });

  final PublicReservarTheme theme;
  final DateTime visibleMonth;
  final DateTime? selectedDate;
  final Map<String, bool> dayHasSlots;
  final bool loading;
  final AsyncValue<List<BusinessHours>> hoursAsync;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final void Function(DateTime day, {required bool enabled}) onDayTap;

  static const _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final hours = hoursAsync.valueOrNull ?? const [];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    // Monday-based offset (weekday 1=Mon .. 7=Sun)
    final leading = firstOfMonth.weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
        boxShadow: [
          BoxShadow(
            color: t.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevMonth,
                icon: Icon(Icons.chevron_left, color: t.text),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  '${_monthNames[visibleMonth.month - 1]} ${visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: t.textStyle(
                    size: 16,
                    weight: FontWeight.w700,
                    color: t.text,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: Icon(Icons.chevron_right, color: t.text),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: t.cardBorder,
                    color: t.primary,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: t.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Consultando disponibilidad…',
                        style: t.textStyle(size: 12, color: t.textSub),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: t.textStyle(
                      size: 11,
                      weight: FontWeight.w600,
                      color: t.textSub,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: leading + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final dayNum = index - leading + 1;
              final day = DateTime(visibleMonth.year, visibleMonth.month, dayNum);
              final isPast = day.isBefore(todayDate);
              final isOpen = isPublicBookingDayOpen(day, hours);
              final key = _dateKey(day);
              final hasSlots = dayHasSlots[key] == true;
              final isLoadingDay = loading && !isPast && isOpen;
              final enabled = !isPast && isOpen && !loading && hasSlots;
              final isSelected = selectedDate != null &&
                  selectedDate!.year == day.year &&
                  selectedDate!.month == day.month &&
                  selectedDate!.day == day.day;
              final isToday = day.year == todayDate.year &&
                  day.month == todayDate.month &&
                  day.day == todayDate.day;

              return _CalendarDayCell(
                theme: t,
                day: dayNum,
                isToday: isToday,
                isSelected: isSelected,
                enabled: enabled,
                isLoading: isLoadingDay,
                hasSlots: hasSlots && !loading,
                isPast: isPast,
                isClosed: !isOpen,
                onTap: () => onDayTap(day, enabled: enabled),
              );
            },
          ),
          const SizedBox(height: 10),
          if (loading)
            Text(
              'Marcando días con turnos libres…',
              textAlign: TextAlign.center,
              style: t.textStyle(size: 11, color: t.textSub),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: t.primary, label: 'Disponible', theme: t),
                const SizedBox(width: 16),
                _LegendDot(color: t.cardBorder, label: 'Sin turnos', theme: t),
              ],
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.theme,
  });

  final Color color;
  final String label;
  final PublicReservarTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textStyle(size: 11, color: theme.textSub)),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.theme,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.enabled,
    required this.isLoading,
    required this.hasSlots,
    required this.isPast,
    required this.isClosed,
    required this.onTap,
  });

  final PublicReservarTheme theme;
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool enabled;
  final bool isLoading;
  final bool hasSlots;
  final bool isPast;
  final bool isClosed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    Color bg = Colors.transparent;
    Color fg = t.text;
    Color border = Colors.transparent;

    if (isSelected) {
      bg = t.primary;
      fg = Colors.white;
    } else if (enabled && hasSlots) {
      bg = t.primarySoft;
      border = t.primary.withValues(alpha: 0.35);
    } else if (isLoading) {
      bg = t.cardFill;
      border = t.cardBorder;
      fg = t.textSub.withValues(alpha: 0.75);
    } else if (isPast || isClosed) {
      fg = t.textSub.withValues(alpha: 0.45);
    } else {
      fg = t.textSub.withValues(alpha: 0.65);
    }

    if (isToday && !isSelected) {
      border = t.primary;
    }

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: isToday && !isSelected ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: t.textStyle(
                size: 14,
                weight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: t.primary.withValues(alpha: 0.85),
                  ),
                ),
              )
            else if (hasSlots && !isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: t.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DaySlotsSection extends StatelessWidget {
  const _DaySlotsSection({
    required this.theme,
    required this.date,
    required this.slotsFuture,
    required this.selected,
    required this.onSelect,
  });

  final PublicReservarTheme theme;
  final DateTime date;
  final Future<List<AvailabilitySlot>>? slotsFuture;
  final AvailabilitySlot? selected;
  final ValueChanged<AvailabilitySlot?> onSelect;

  String _formatDate(DateTime d) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final t = theme;
    if (slotsFuture == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horarios · ${_formatDate(date)}',
          style: t.textStyle(size: 15, weight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<AvailabilitySlot>>(
          future: slotsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: t.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Cargando horarios…',
                      style: t.textStyle(size: 13, color: t.textSub),
                    ),
                  ],
                ),
              );
            }
            if (snap.hasError) {
              return Text(
                'No se pudieron cargar los horarios.',
                style: t.textStyle(color: t.textSub),
              );
            }
            final slots = snap.data ?? [];
            if (slots.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: t.cardFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_busy_outlined, size: 40, color: t.textSub),
                    const SizedBox(height: 8),
                    Text(
                      'No hay turnos para este día con el filtro actual.',
                      textAlign: TextAlign.center,
                      style: t.textStyle(size: 13, color: t.textSub),
                    ),
                  ],
                ),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                final isSel = selected?.inicio == slot.inicio;
                return GestureDetector(
                  onTap: () => onSelect(isSel ? null : slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSel ? t.primary : t.cardFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? t.primary : t.cardBorder,
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      slot.label,
                      style: t.textStyle(
                        size: 14,
                        weight: FontWeight.w600,
                        color: isSel ? Colors.white : t.text,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
