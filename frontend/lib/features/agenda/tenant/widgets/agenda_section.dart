import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/staff_member.dart';
import '../../../../providers/agenda/agenda_api_provider.dart';
import '../../../../providers/agenda/tenant/agenda_bookings_provider.dart';
import '../../../../providers/agenda/tenant/agenda_month_provider.dart';
import '../../../../providers/agenda/tenant/agenda_week_provider.dart';
import '../../../../providers/agenda/tenant/business_staff_provider.dart';
import '../../register/konecta_tokens.dart';
import 'day_view.dart';
import 'month_view.dart';
import 'new_turno_panel.dart';
import 'week_view.dart';

enum _AgendaViewMode { month, week, day }

const _kMonths = [
  '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];
const _kWeekDaysFull = [
  '', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];

class AgendaSection extends ConsumerStatefulWidget {
  const AgendaSection({
    super.key,
    required this.tenantId,
    required this.businesses,
    this.businessId,
    this.onBusinessSelected,
  });

  final String tenantId;
  final List<dynamic> businesses;
  final String? businessId;
  final void Function(String businessId)? onBusinessSelected;

  @override
  ConsumerState<AgendaSection> createState() => _AgendaSectionState();
}

class _AgendaSectionState extends ConsumerState<AgendaSection> {
  _AgendaViewMode _mode = _AgendaViewMode.month;
  DateTime _focusDate = DateTime.now();
  String? _selectedProId;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Monday of the week that contains [date].
  DateTime _weekStart(DateTime date) => DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: date.weekday - 1));

  Future<void> _copyPublicLink() async {
    final api = ref.read(agendaApiServiceProvider);
    try {
      final result = await api.mePublicLink();
      final url = result['url'];
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        _showSnack('No se pudo generar el vínculo público');
        return;
      }
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      _showSnack('Vínculo copiado');
    } catch (e) {
      if (mounted) _showSnack('Error al copiar vínculo');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _goToPrevious() {
    setState(() {
      switch (_mode) {
        case _AgendaViewMode.month:
          _focusDate = DateTime(_focusDate.year, _focusDate.month - 1, 1);
        case _AgendaViewMode.week:
          _focusDate = _focusDate.subtract(const Duration(days: 7));
        case _AgendaViewMode.day:
          _focusDate = _focusDate.subtract(const Duration(days: 1));
      }
    });
  }

  void _goToNext() {
    setState(() {
      switch (_mode) {
        case _AgendaViewMode.month:
          _focusDate = DateTime(_focusDate.year, _focusDate.month + 1, 1);
        case _AgendaViewMode.week:
          _focusDate = _focusDate.add(const Duration(days: 7));
        case _AgendaViewMode.day:
          _focusDate = _focusDate.add(const Duration(days: 1));
      }
    });
  }

  void _openNewTurno({DateTime? start, String? proId}) {
    final businessId = widget.businessId;
    if (businessId == null) return;
    showNewTurnoPanel(
      context,
      tenantId: widget.tenantId,
      businessId: businessId,
      initialDate: start,
      initialProId: proId,
    );
  }

  String _monthTitle() => '${_kMonths[_focusDate.month]} ${_focusDate.year}';

  String _weekTitle() {
    final start = _weekStart(_focusDate);
    final end = start.add(const Duration(days: 6));
    if (start.month == end.month) {
      return '${start.day} – ${end.day} de ${_kMonths[start.month]} ${start.year}';
    }
    return '${start.day} ${_kMonths[start.month]} – ${end.day} ${_kMonths[end.month]} ${start.year}';
  }

  String _dayTitle() {
    final wd = _kWeekDaysFull[_focusDate.weekday];
    final d  = _focusDate.day;
    final m  = _kMonths[_focusDate.month];
    return '$wd $d de $m';
  }

  String _currentTitle() {
    switch (_mode) {
      case _AgendaViewMode.month: return _monthTitle();
      case _AgendaViewMode.week:  return _weekTitle();
      case _AgendaViewMode.day:   return _dayTitle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessId = widget.businessId;
    if (businessId == null || businessId.isEmpty) {
      return _EmptyState(
        icon: Icons.store_mall_directory_outlined,
        title: 'Seleccioná una ubicación',
        subtitle: 'Elegí la ubicación para ver el calendario.',
      );
    }

    final staffState = ref.watch(
      businessStaffProvider((tenantId: widget.tenantId, businessId: businessId)),
    );
    final activeStaff = staffState.members.where((s) => s.activo).toList();
    final ws = _weekStart(_focusDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Two-column header: left = pill + date, right = buttons + tabs ────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT: staff pill (top) + date+arrows (bottom)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StaffPill(activeStaff: activeStaff),
                  const SizedBox(height: 22),
                  _DateNavRow(
                    mode: _mode,
                    title: _currentTitle(),
                    onPrev: _goToPrevious,
                    onNext: _goToNext,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // RIGHT: action buttons (top) + view tabs (bottom)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GhostButton(
                      icon: Icons.link,
                      label: 'Copiar vínculo',
                      onTap: _copyPublicLink,
                    ),
                    const SizedBox(width: 8),
                    _NewTurnoButton(onTap: () => _openNewTurno()),
                  ],
                ),
                const SizedBox(height: 22),
                _ViewTabs(
                  mode: _mode,
                  onModeChange: (m) => setState(() => _mode = m),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        // ── Stats mono row ────────────────────────────────────────────────────
        _StatsRow(
          businessId: businessId,
          mode: _mode,
          date: _focusDate,
          weekStart: ws,
          tenantId: widget.tenantId,
        ),
        const SizedBox(height: 12),
        // ── Calendar ─────────────────────────────────────────────────────────
        Expanded(
          child: switch (_mode) {
            _AgendaViewMode.month => MonthView(
                date: _focusDate,
                businessId: businessId,
                tenantId: widget.tenantId,
                selectedProId: _selectedProId,
                onDayTap: (d) => setState(() {
                  _focusDate = d;
                  _mode = _AgendaViewMode.day;
                }),
              ),
            _AgendaViewMode.week => WeekView(
                weekStart: ws,
                businessId: businessId,
                tenantId: widget.tenantId,
                onSlotTap: (start, proId) =>
                    _openNewTurno(start: start, proId: proId),
                onTurnoTap: (_) {},
              ),
            _AgendaViewMode.day => DayView(
                date: _focusDate,
                businessId: businessId,
                tenantId: widget.tenantId,
                visibleProId: _selectedProId,
                onSlotTap: (start, proId) =>
                    _openNewTurno(start: start, proId: proId),
                onTurnoTap: (_) {},
              ),
          },
        ),
      ],
    );
  }
}

// ── Staff pill ─────────────────────────────────────────────────────────────────

class _StaffPill extends StatelessWidget {
  const _StaffPill({required this.activeStaff});

  final List<StaffMember> activeStaff;

  Color _colorFor(int idx) => KTokens.proPalette[idx % KTokens.proPalette.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: KTokens.bg,
        borderRadius: BorderRadius.circular(KTokens.rPill),
        border: Border.all(color: KTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 16,
            child: Stack(
              children: List.generate(
                activeStaff.length.clamp(0, 3),
                (i) => Positioned(
                  left: i * 6.0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _colorFor(i),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Todas las agendas · ${activeStaff.length} activa${activeStaff.length != 1 ? 's' : ''}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: KTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nueva agenda button ────────────────────────────────────────────────────────

class _NewTurnoButton extends StatelessWidget {
  const _NewTurnoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: KTokens.ink,
          borderRadius: BorderRadius.circular(KTokens.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              'Nueva agenda',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KTokens.rPill),
          border: Border.all(color: KTokens.borderStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: KTokens.inkMuted),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: KTokens.inkMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Date nav row (title + arrows only) ────────────────────────────────────────

class _DateNavRow extends StatelessWidget {
  const _DateNavRow({
    required this.mode,
    required this.title,
    required this.onPrev,
    required this.onNext,
  });

  final _AgendaViewMode mode;
  final String title;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  Widget _arrowBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: KTokens.border),
          ),
          child: Icon(icon, size: 18, color: KTokens.inkMuted),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: mode == _AgendaViewMode.day
              ? Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: KTokens.accent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: KTokens.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        const SizedBox(width: 10),
        _arrowBtn(Icons.chevron_left, onPrev),
        const SizedBox(width: 4),
        _arrowBtn(Icons.chevron_right, onNext),
      ],
    );
  }
}

class _ViewTabs extends StatelessWidget {
  const _ViewTabs({required this.mode, required this.onModeChange});

  final _AgendaViewMode mode;
  final void Function(_AgendaViewMode) onModeChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: KTokens.bg,
        borderRadius: BorderRadius.circular(KTokens.rMd),
        border: Border.all(color: KTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(
            label: 'Mes',
            selected: mode == _AgendaViewMode.month,
            onTap: () => onModeChange(_AgendaViewMode.month),
          ),
          _Tab(
            label: 'Semana',
            selected: mode == _AgendaViewMode.week,
            onTap: () => onModeChange(_AgendaViewMode.week),
          ),
          _Tab(
            label: 'Día',
            selected: mode == _AgendaViewMode.day,
            onTap: () => onModeChange(_AgendaViewMode.day),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(KTokens.rSm),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? KTokens.accent : KTokens.inkSoft,
          ),
        ),
      ),
    );
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow({
    required this.businessId,
    required this.mode,
    required this.date,
    required this.weekStart,
    required this.tenantId,
  });

  final String businessId;
  final _AgendaViewMode mode;
  final DateTime date;
  final DateTime weekStart;
  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (mode) {
      case _AgendaViewMode.month:
        final async = ref.watch(agendaMonthBookingsProvider((
          businessId: businessId,
          year: date.year,
          month: date.month,
        )));
        return async.when(
          loading: () => _statsText('— TURNOS'),
          error: (_, e) => _statsText('— TURNOS'),
          data: (b) => _statsText('${b.length} TURNOS'),
        );

      case _AgendaViewMode.week:
        final async = ref.watch(agendaWeekBookingsProvider((
          businessId: businessId,
          weekStart: weekStart,
        )));
        return async.when(
          loading: () => _statsText('— TURNOS'),
          error: (_, e) => _statsText('— TURNOS'),
          data: (b) => _statsText('${b.length} TURNOS ESTA SEMANA'),
        );

      case _AgendaViewMode.day:
        final async = ref.watch(agendaBookingsProvider((
          businessId: businessId,
          day: date,
        )));
        return async.when(
          loading: () => _statsText('— TURNOS'),
          error: (_, e) => _statsText('— TURNOS'),
          data: (b) => _statsText('${b.length} TURNOS HOY'),
        );
    }
  }

  Widget _statsText(String text) => Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          letterSpacing: 1.2,
          color: KTokens.inkSoft,
          fontWeight: FontWeight.w500,
        ),
      );
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: KTokens.inkPlaceholder),
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w600, color: KTokens.ink)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
