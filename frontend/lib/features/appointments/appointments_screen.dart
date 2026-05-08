import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../models/appointment.dart';
import '../../models/service.dart';
import '../agenda/theme/agenda_tokens.dart';
import '../../providers/auth_provider.dart';

enum _ScheduleView { day, week, month }

/// Citas del bot (admin): estilo «Mi Agenda» del landing, ancho completo y vistas día/semana/mes.
class AppointmentsScreen extends ConsumerStatefulWidget {
  final String botId;
  final String tenantId;
  final bool embedded;

  const AppointmentsScreen({
    super.key,
    required this.botId,
    required this.tenantId,
    this.embedded = false,
  });

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  List<Appointment> _appointments = [];
  List<Service> _services = [];
  bool _loading = true;
  String? _error;

  late DateTime _loadFrom;
  late DateTime _loadTo;

  late DateTime _selectedDay;
  late DateTime _weekStart;

  /// Primer día del mes mostrado en vista «Mes».
  late DateTime _monthCursor;

  _ScheduleView _view = _ScheduleView.day;

  bool _includeCancelled = false;

  final TextEditingController _docFilterCtrl = TextEditingController();
  /// Valor de filtro enviado al API (texto tal cual; el backend normaliza la cédula).
  String? _docFilterApplied;

  static const _kBorderLight = Color(0xFFE2E8F0);

  static const _cardAccentColors = [
    Color(0xFF10B981),
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
  ];

  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static String _dateToStr(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _mondayOfWeek(DateTime date) {
    final d = _dateOnly(date);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  static DateTime? _parseAppointmentDate(String raw) {
    try {
      final p = raw.split('-');
      if (p.length != 3) return null;
      return DateTime(
        int.parse(p[0]),
        int.parse(p[1]),
        int.parse(p[2]),
      );
    } catch (_) {
      return null;
    }
  }

  static String _formatTimeShort(String raw) {
    if (raw.isEmpty) return raw;
    final t = raw.trim();
    if (t.length >= 5 && t[4] == ':') return t.substring(0, 5);
    return t;
  }

  static String _weekdayShortEs(DateTime d) {
    const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return names[d.weekday - DateTime.monday];
  }

  String _dayHeaderLine(DateTime d) {
    final today = _dateOnly(DateTime.now());
    final x = _dateOnly(d);
    final wd = _weekdayShortEs(d);
    if (x == today) {
      return 'Hoy · $wd ${d.day}';
    }
    return '$wd ${d.day}';
  }

  List<Appointment> _filteredForDay(DateTime day) {
    final sel = _dateOnly(day);
    final list = _appointments.where((a) {
      final ad = _parseAppointmentDate(a.appointmentDate);
      if (ad == null) return false;
      if (!_includeCancelled && a.status.toLowerCase() == 'cancelled') {
        return false;
      }
      return _dateOnly(ad) == sel;
    }).toList();
    list.sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));
    return list;
  }

  int _countForDay(DateTime day) {
    return _filteredForDay(day).length;
  }

  void _ensureRangeCoversMonth(DateTime monthFirstDay) {
    final last = DateTime(monthFirstDay.year, monthFirstDay.month + 1, 0);
    var from = _loadFrom;
    var to = _loadTo;
    var changed = false;
    if (monthFirstDay.isBefore(from)) {
      from = _dateOnly(monthFirstDay);
      changed = true;
    }
    if (last.isAfter(to)) {
      to = _dateOnly(last);
      changed = true;
    }
    if (changed) {
      setState(() {
        _loadFrom = from;
        _loadTo = to;
      });
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final fromStr = _dateToStr(_loadFrom);
      final toStr = _dateToStr(_loadTo);
      final list = await api.getAppointments(
        widget.tenantId,
        from: fromStr,
        to: toStr,
        includeCancelled: _includeCancelled,
        customerDocument: _docFilterApplied,
      );
      List<Service> svc = [];
      try {
        svc = await api.getServices(widget.tenantId);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _appointments = list;
          _services = svc;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _initRangeAndWeek() {
    final now = DateTime.now();
    _selectedDay = _dateOnly(now);
    _weekStart = _mondayOfWeek(now);
    _monthCursor = DateTime(now.year, now.month, 1);
    _loadFrom = _dateOnly(now.subtract(const Duration(days: 14)));
    _loadTo = _dateOnly(now.add(const Duration(days: 120)));
  }

  @override
  void initState() {
    super.initState();
    _initRangeAndWeek();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _docFilterCtrl.dispose();
    super.dispose();
  }

  void _applyDocumentFilter() {
    final t = _docFilterCtrl.text.trim();
    setState(() => _docFilterApplied = t.isEmpty ? null : t);
    _load();
  }

  Widget _documentFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _docFilterCtrl,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Buscar citas por cédula o documento',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _applyDocumentFilter(),
                ),
              ),
              IconButton(
                tooltip: 'Filtrar',
                onPressed: _applyDocumentFilter,
                icon: Icon(Icons.search, color: AgendaTokens.primary),
              ),
            ],
          ),
          if (_docFilterApplied != null && _docFilterApplied!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Mostrando citas del documento: $_docFilterApplied',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AgendaTokens.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _docFilterApplied = null;
                        _docFilterCtrl.clear();
                      });
                      _load();
                    },
                    child: Text(
                      'Quitar filtro',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final from = await showDatePicker(
      context: context,
      initialDate: _loadFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (from == null || !mounted) return;
    final to = await showDatePicker(
      context: context,
      initialDate: _loadTo.isBefore(from) ? from : _loadTo,
      firstDate: from,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (to == null || !mounted) return;
    setState(() {
      _loadFrom = _dateOnly(from);
      _loadTo = _dateOnly(to);
    });
    _load();
  }

  Future<void> _addAppointment() async {
    final nameController = TextEditingController();
    final docController = TextEditingController();
    final timeController = TextEditingController(text: '09:00');
    final serviceNameController = TextEditingController();
    String? selectedService = _services.isNotEmpty ? _services.first.name : null;
    DateTime date = DateTime.now();

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AgendaTokens.dialogRadius),
          ),
          title: Text(
            'Nueva cita',
            style: AgendaTokens.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AgendaTokens.dark,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del cliente',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: docController,
                    decoration: const InputDecoration(
                      labelText: 'Documento (cédula / DNI)',
                      hintText: 'Obligatorio para expediente del usuario',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_services.isEmpty)
                    TextField(
                      controller: serviceNameController,
                      decoration: const InputDecoration(
                        labelText: 'Servicio',
                        hintText: 'Nombre del servicio',
                      ),
                    )
                  else
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Servicio'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedService,
                          items: _services
                              .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                              .toList(),
                          onChanged: (v) => setDialogState(() => selectedService = v),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Fecha'),
                    subtitle: Text('${date.day}/${date.month}/${date.year}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setDialogState(() => date = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: 'Hora',
                      hintText: '09:00',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AgendaTokens.primaryDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nombre requerido')),
                  );
                  return;
                }
                if (docController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Documento es obligatorio para el expediente del usuario',
                      ),
                    ),
                  );
                  return;
                }
                final serviceName = _services.isEmpty
                    ? serviceNameController.text.trim()
                    : (selectedService ?? '');
                if (serviceName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Indica el servicio')),
                  );
                  return;
                }
                final time =
                    timeController.text.trim().isEmpty ? '09:00' : timeController.text.trim();
                Navigator.pop(ctx);
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.createAppointment(widget.tenantId, {
                    'customerName': nameController.text.trim(),
                    'customerDocument': docController.text.trim(),
                    'serviceName': serviceName,
                    'appointmentDate': _dateToStr(date),
                    'appointmentTime': time,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cita creada'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                    setState(() {
                      _selectedDay = _dateOnly(date);
                      _weekStart = _mondayOfWeek(_selectedDay);
                      _monthCursor = DateTime(_selectedDay.year, _selectedDay.month, 1);
                    });
                    _load();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCardsFor(List<Appointment> items) {
    return List.generate(items.length, (i) {
      final a = items[i];
      final cancelled = a.status.toLowerCase() == 'cancelled';
      final color = cancelled
          ? AgendaTokens.textMuted
          : _cardAccentColors[i % _cardAccentColors.length];
      return _AppointmentStyleCard(
        time: _formatTimeShort(a.appointmentTime),
        name: a.customerName,
        document: a.customerDocument,
        service: a.serviceName,
        subtitleStatus: a.status,
        accent: color,
        muted: cancelled,
      );
    });
  }

  Widget _viewModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<_ScheduleView>(
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          segments: [
            ButtonSegment(
              value: _ScheduleView.day,
              label: Text('Día', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            ButtonSegment(
              value: _ScheduleView.week,
              label: Text('Semana', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            ButtonSegment(
              value: _ScheduleView.month,
              label: Text('Mes', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
          selected: {_view},
          onSelectionChanged: (s) {
            final v = s.first;
            setState(() {
              _view = v;
              if (v == _ScheduleView.week) {
                _weekStart = _mondayOfWeek(_selectedDay);
              }
              if (v == _ScheduleView.month) {
                _monthCursor = DateTime(_selectedDay.year, _selectedDay.month, 1);
                _ensureRangeCoversMonth(_monthCursor);
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildDaySection() {
    final filtered = _filteredForDay(_selectedDay);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekStrip(
          weekStart: _weekStart,
          selectedDay: _selectedDay,
          onSelectDay: (d) => setState(() => _selectedDay = _dateOnly(d)),
          onPrevWeek: () => setState(() {
            _weekStart = _weekStart.subtract(const Duration(days: 7));
          }),
          onNextWeek: () => setState(() {
            _weekStart = _weekStart.add(const Duration(days: 7));
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                _dayHeaderLine(_selectedDay),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AgendaTokens.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AgendaTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${filtered.length} turno${filtered.length == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AgendaTokens.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Text(
              'No hay citas este día en el rango cargado.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AgendaTokens.textMuted,
              ),
            ),
          )
        else
          ..._buildCardsFor(filtered),
      ],
    );
  }

  Widget _buildWeekSection() {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    var totalTurnos = 0;
    for (final d in days) {
      totalTurnos += _countForDay(d);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekNavHeader(
          title:
              'Semana: ${days.first.day}/${days.first.month} – ${days.last.day}/${days.last.month}/${days.last.year}',
          subtitle: '$totalTurnos turno${totalTurnos == 1 ? '' : 's'} en total',
          onPrev: () => setState(() {
            _weekStart = _weekStart.subtract(const Duration(days: 7));
          }),
          onNext: () => setState(() {
            _weekStart = _weekStart.add(const Duration(days: 7));
          }),
        ),
        for (final d in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Text(
                  '${_weekdayShortEs(d)} ${d.day}/${d.month}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AgendaTokens.dark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AgendaTokens.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_countForDay(d)}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AgendaTokens.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_filteredForDay(d).isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Text(
                'Sin citas',
                style: GoogleFonts.poppins(fontSize: 12, color: AgendaTokens.textMuted),
              ),
            )
          else
            ..._buildCardsFor(_filteredForDay(d)),
        ],
      ],
    );
  }

  Widget _buildMonthSection() {
    final m = _monthCursor;
    final lastDay = DateTime(m.year, m.month + 1, 0).day;
    final firstWeekday = DateTime(m.year, m.month, 1).weekday;
    final leadingBlanks = firstWeekday - DateTime.monday;
    final today = _dateOnly(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthNavHeader(
          title: '${_meses[m.month - 1]} ${m.year}',
          onPrev: () {
            final prev = DateTime(m.year, m.month - 1, 1);
            setState(() => _monthCursor = prev);
            _ensureRangeCoversMonth(prev);
          },
          onNext: () {
            final next = DateTime(m.year, m.month + 1, 1);
            setState(() => _monthCursor = next);
            _ensureRangeCoversMonth(next);
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: List.generate(7, (i) {
              const letters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
              return Expanded(
                child: Center(
                  child: Text(
                    letters[i],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AgendaTokens.textMuted,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.15,
          ),
          itemCount: 42,
          itemBuilder: (ctx, index) {
            final dayNum = index - leadingBlanks + 1;
            if (dayNum < 1 || dayNum > lastDay) {
              return const SizedBox.shrink();
            }
            final cellDate = DateTime(m.year, m.month, dayNum);
            final count = _countForDay(cellDate);
            final isToday = _dateOnly(cellDate) == today;
            final isSelected = _dateOnly(cellDate) == _dateOnly(_selectedDay);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() {
                  _selectedDay = _dateOnly(cellDate);
                  _weekStart = _mondayOfWeek(_selectedDay);
                }),
                borderRadius: BorderRadius.circular(10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AgendaTokens.primary.withValues(alpha: 0.15)
                        : (isToday ? AgendaTokens.primary.withValues(alpha: 0.06) : null),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AgendaTokens.primary
                          : (isToday
                              ? AgendaTokens.primary.withValues(alpha: 0.35)
                              : _kBorderLight),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AgendaTokens.dark,
                        ),
                      ),
                      if (count > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AgendaTokens.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Día seleccionado: ${_dayHeaderLine(_selectedDay)} · ${_filteredForDay(_selectedDay).length} turno${_filteredForDay(_selectedDay).length == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AgendaTokens.textMuted,
            ),
          ),
        ),
        if (_filteredForDay(_selectedDay).isNotEmpty)
          ..._buildCardsFor(_filteredForDay(_selectedDay)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AgendaTokens.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_error',
                textAlign: TextAlign.center,
                style: AgendaTokens.poppins(color: Colors.red[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AgendaTokens.primaryDark,
                  foregroundColor: Colors.white,
                ),
                onPressed: _load,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final panel = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiAgendaAppBar(
              onRefresh: _load,
              onPickRange: _pickRange,
            ),
            _documentFilterBar(),
            _viewModeSelector(),
            if (_view == _ScheduleView.day) _buildDaySection(),
            if (_view == _ScheduleView.week) _buildWeekSection(),
            if (_view == _ScheduleView.month) _buildMonthSection(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: FilterChip(
                label: Text(
                  'Ver canceladas',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: _includeCancelled,
                onSelected: (v) {
                  setState(() => _includeCancelled = v);
                  _load();
                },
                selectedColor: AgendaTokens.primary.withValues(alpha: 0.15),
                checkmarkColor: AgendaTokens.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Material(
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _addAppointment,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AgendaTokens.primaryDark, AgendaTokens.accent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '+ Nueva cita',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final body = RefreshIndicator(
      color: AgendaTokens.primary,
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (ctx, c) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: panel,
            ),
          );
        },
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: AgendaTokens.surface,
      appBar: AppBar(
        backgroundColor: AgendaTokens.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Citas del bot',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: body,
    );
  }
}

class _MiAgendaAppBar extends StatelessWidget {
  const _MiAgendaAppBar({
    required this.onRefresh,
    required this.onPickRange,
  });

  final VoidCallback onRefresh;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AgendaTokens.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'Mi Agenda',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Rango de fechas (carga en servidor)',
            icon: const Icon(Icons.date_range_outlined, color: Colors.white, size: 20),
            onPressed: onPickRange,
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              onPressed: onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekNavHeader extends StatelessWidget {
  const _WeekNavHeader({
    required this.title,
    required this.subtitle,
    required this.onPrev,
    required this.onNext,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AgendaTokens.primary.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: AgendaTokens.dark.withValues(alpha: 0.7)),
                onPressed: onPrev,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AgendaTokens.dark,
                      ),
                    ),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AgendaTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: AgendaTokens.dark.withValues(alpha: 0.7)),
                onPressed: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthNavHeader extends StatelessWidget {
  const _MonthNavHeader({
    required this.title,
    required this.onPrev,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AgendaTokens.primary.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: AgendaTokens.dark.withValues(alpha: 0.7)),
            onPressed: onPrev,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AgendaTokens.dark,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: AgendaTokens.dark.withValues(alpha: 0.7)),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.weekStart,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  final DateTime weekStart;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  static const _letters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AgendaTokens.primary.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: AgendaTokens.dark.withValues(alpha: 0.7)),
                onPressed: onPrevWeek,
              ),
              Expanded(
                child: Text(
                  'Semana del ${weekStart.day}/${weekStart.month}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AgendaTokens.textMuted,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: AgendaTokens.dark.withValues(alpha: 0.7)),
                onPressed: onNextWeek,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final d = weekStart.add(Duration(days: i));
              final sel = d.year == selectedDay.year &&
                  d.month == selectedDay.month &&
                  d.day == selectedDay.day;
              return _DayChip(
                label: _letters[i],
                day: d.day,
                selected: sel,
                onTap: () => onSelectDay(d),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AgendaTokens.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AgendaTokens.textMuted,
              ),
            ),
            Text(
              '$day',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AgendaTokens.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentStyleCard extends StatelessWidget {
  const _AppointmentStyleCard({
    required this.time,
    required this.name,
    this.document,
    required this.service,
    required this.subtitleStatus,
    required this.accent,
    required this.muted,
  });

  final String time;
  final String name;
  final String? document;
  final String service;
  final String subtitleStatus;
  final Color accent;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final line = muted ? '$service · $subtitleStatus' : service;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: muted ? 0.04 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AgendaTokens.dark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (document != null && document!.isNotEmpty)
                  Text(
                    'Doc. $document',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AgendaTokens.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  line,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AgendaTokens.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
