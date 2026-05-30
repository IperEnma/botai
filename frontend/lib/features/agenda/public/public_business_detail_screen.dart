import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/availability_slot.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/public/public_business_detail_provider.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen entry point
// ─────────────────────────────────────────────────────────────────────────────

class PublicBusinessDetailScreen extends ConsumerWidget {
  const PublicBusinessDetailScreen({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(publicBusinessProvider(businessId));
    final servicesAsync = ref.watch(publicBusinessServicesProvider(businessId));

    return businessAsync.when(
      loading: () => const Scaffold(body: AgendaLoadingView()),
      error: (e, _) => Scaffold(
        body: AgendaErrorView(
          message: 'No se pudo cargar el negocio: $e',
          onRetry: () => ref.refresh(publicBusinessProvider(businessId)),
        ),
      ),
      data: (b) => _DetailPage(business: b, servicesAsync: servicesAsync),
    );
  }
}

/// Variante que carga todo por `slug` (URL amigable) sin redireccionar a una URL con UUID.
class PublicBusinessDetailBySlugScreen extends ConsumerWidget {
  const PublicBusinessDetailBySlugScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(publicBusinessBySlugProvider(slug));
    final servicesAsync = ref.watch(publicBusinessServicesBySlugProvider(slug));

    return businessAsync.when(
      loading: () => const Scaffold(body: AgendaLoadingView()),
      error: (e, _) => Scaffold(
        body: AgendaErrorView(
          message: 'No se pudo cargar el negocio: $e',
          onRetry: () => ref.refresh(publicBusinessBySlugProvider(slug)),
        ),
      ),
      data: (b) => _DetailPage(business: b, servicesAsync: servicesAsync),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full page
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPage extends StatelessWidget {
  const _DetailPage({required this.business, required this.servicesAsync});

  final Business business;
  final AsyncValue<List<AgendaService>> servicesAsync;

  Color get _primaryColor {
    final hex = business.colorPrimario;
    if (hex == null) return const Color(0xFF6366F1);
    final val = int.tryParse('FF${hex.replaceAll('#', '')}', radix: 16);
    return val != null ? Color(val) : const Color(0xFF6366F1);
  }

  Color get _bgColor {
    final hex = business.colorFondo;
    if (hex == null) return Colors.white;
    final val = int.tryParse('FF${hex.replaceAll('#', '')}', radix: 16);
    return val != null ? Color(val) : Colors.white;
  }

  bool get _bgIsDark => _bgColor.computeLuminance() < 0.4;

  String get _fontFamily => business.fontFamily ?? 'Roboto';

  bool get _hasSocial =>
      business.instagramUrl != null ||
      business.tiktokUrl != null ||
      business.facebookUrl != null;

  void _openBooking(BuildContext context, AgendaService? service,
      List<AgendaService> services) {
    final primary = _primaryColor;
    final bg = _bgColor;
    final dark = _bgIsDark;
    final font = _fontFamily;

    final AgendaService? svc =
        service ?? (services.length == 1 ? services.first : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _BookingSheet(
        business: business,
        primaryColor: primary,
        bgColor: bg,
        dark: dark,
        fontFamily: font,
        preselectedService: svc,
        allServices: services,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = _primaryColor;
    final bg = _bgColor;
    final dark = _bgIsDark;
    final font = _fontFamily;
    final textColor = dark ? Colors.white : Colors.black87;
    final subColor = dark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Pinned app bar ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            title: Text(business.nombre,
                style: const TextStyle(color: Colors.white)),
            expandedHeight: 0,
          ),

          // ── Header: banner + avatar + info ────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: bg,
              child: Column(
                children: [
                  Container(height: 80, color: primary),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Column(
                      children: [
                        _AvatarCircle(
                          logoUrl: business.logoUrl,
                          nombre: business.nombre,
                          color: primary,
                          size: 80,
                          borderColor: bg,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            business.nombre,
                            textAlign: TextAlign.center,
                            style: _fs(font,
                                size: 22,
                                weight: FontWeight.w700,
                                color: textColor),
                          ),
                        ),
                        if (business.descripcion != null &&
                            business.descripcion!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              business.descripcion!,
                              textAlign: TextAlign.center,
                              style: _fs(font, size: 14, color: subColor),
                            ),
                          ),
                        ],
                        if (business.categorias.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final cat
                                  in business.categorias.take(4))
                                Chip(
                                  label: Text(cat,
                                      style: _fs(font,
                                          size: 11, color: primary)),
                                  backgroundColor:
                                      primary.withValues(alpha: 0.1),
                                  side: BorderSide.none,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                  labelPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8),
                                ),
                            ],
                          ),
                        ],
                        if (_hasSocial) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              if (business.instagramUrl != null)
                                _SocialChip(
                                    label: 'Instagram', color: primary),
                              if (business.tiktokUrl != null)
                                _SocialChip(
                                    label: 'TikTok', color: primary),
                              if (business.facebookUrl != null)
                                _SocialChip(
                                    label: 'Facebook', color: primary),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        // CTA button (opens booking flow)
                        servicesAsync.when(
                          loading: () => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                onPressed: null,
                                child: Text('Reservar turno',
                                    style: _fs(font,
                                        size: 15,
                                        weight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (services) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                onPressed: services.isEmpty
                                    ? null
                                    : () => _openBooking(
                                        context, null, services),
                                child: Text(
                                    services.isEmpty
                                        ? 'Sin servicios disponibles'
                                        : 'Reservar turno',
                                    style: _fs(font,
                                        size: 15,
                                        weight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Services section ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: bg,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                      color: dark
                          ? Colors.white24
                          : Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text('Servicios',
                      style: _fs(font,
                          size: 16,
                          weight: FontWeight.w700,
                          color: textColor)),
                  const SizedBox(height: 12),
                  servicesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Text(
                      'No se pudieron cargar los servicios.',
                      style: TextStyle(color: subColor),
                    ),
                    data: (list) => list.isEmpty
                        ? Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Este negocio todavía no publicó servicios.',
                              style: TextStyle(color: subColor),
                            ),
                          )
                        : Column(
                            children: [
                              for (final s in list)
                                _ServiceTile(
                                  service: s,
                                  primaryColor: primary,
                                  fontFamily: font,
                                  dark: dark,
                                  onBook: () => _openBooking(
                                      context, s, list),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

enum _Step { service, staff, date, slots }

class _BookingSheet extends ConsumerStatefulWidget {
  const _BookingSheet({
    required this.business,
    required this.primaryColor,
    required this.bgColor,
    required this.dark,
    required this.fontFamily,
    required this.preselectedService,
    required this.allServices,
  });

  final Business business;
  final Color primaryColor;
  final Color bgColor;
  final bool dark;
  final String fontFamily;
  final AgendaService? preselectedService;
  final List<AgendaService> allServices;

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  late _Step _step;
  AgendaService? _service;
  bool _anyStaff = false;
  StaffMember? _selectedStaff;
  DateTime? _selectedDate;
  AvailabilitySlot? _selectedSlot;
  Future<List<AvailabilitySlot>>? _slotsFuture;

  Color get _primary => widget.primaryColor;
  Color get _bg => widget.dark ? const Color(0xFF1E293B) : Colors.white;
  Color get _textColor =>
      widget.dark ? Colors.white : Colors.black87;
  Color get _subColor =>
      widget.dark ? Colors.white60 : Colors.grey.shade600;
  String get _font => widget.fontFamily;

  @override
  void initState() {
    super.initState();
    _service = widget.preselectedService;
    _step =
        widget.preselectedService != null ? _Step.staff : _Step.service;
  }

  void _goBack() {
    setState(() {
      switch (_step) {
        case _Step.service:
          Navigator.of(context).pop();
        case _Step.staff:
          if (widget.preselectedService != null) {
            Navigator.of(context).pop();
          } else {
            _step = _Step.service;
          }
        case _Step.date:
          _step = _Step.staff;
          _selectedDate = null;
          _selectedSlot = null;
        case _Step.slots:
          _step = _Step.date;
          _selectedSlot = null;
      }
    });
  }

  void _selectStaff({StaffMember? member, bool any = false}) {
    setState(() {
      _anyStaff = any;
      _selectedStaff = member;
      _step = _Step.date;
      _selectedDate = null;
      _selectedSlot = null;
    });
  }

  void _selectDate(DateTime date) {
    final staffId = _anyStaff ? null : _selectedStaff?.id;
    final key = (
      businessId: widget.business.id,
      serviceId: _service!.id,
      staffMemberId: staffId,
      date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    );
    setState(() {
      _selectedDate = date;
      _selectedSlot = null;
      _step = _Step.slots;
      _slotsFuture =
          ref.read(availabilityProvider(key).future);
    });
  }

  void _selectSlot(AvailabilitySlot slot) {
    setState(() => _selectedSlot = slot);
  }

  Future<void> _confirm() async {
    final svc = _service;
    final slot = _selectedSlot;
    if (svc == null || slot == null) return;

    try {
      final payload = await _askClientData();
      if (payload == null) return;

      final api = ref.read(agendaApiServiceProvider);
      final client = await api.createClient(
        businessId: widget.business.id,
        nombre: payload.nombre,
        email: payload.email,
        telefono: payload.telefono,
      );
      await api.publicCreateBooking(
            businessId: widget.business.id,
            serviceId: svc.id,
            staffMemberId: _anyStaff ? null : _selectedStaff?.id,
            fechaHoraInicio: slot.inicio,
            clientId: client.id,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Turno solicitado! ${svc.nombre} · ${slot.label}',
                ),
              ),
            ],
          ),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo solicitar el turno: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<_ClientPayload?> _askClientData() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();

    return showDialog<_ClientPayload>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tus datos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: telCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final nombre = nombreCtrl.text.trim();
              if (nombre.isEmpty) return;
              Navigator.of(ctx).pop(_ClientPayload(
                nombre: nombre,
                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                telefono: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
              ));
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case _Step.service:
        return 'Elegí un servicio';
      case _Step.staff:
        return 'Elegí un miembro del equipo';
      case _Step.date:
        return 'Elegí una fecha';
      case _Step.slots:
        return 'Elegí un horario';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _goBack,
                  child: Icon(Icons.arrow_back_ios_new,
                      size: 18, color: _textColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _stepTitle,
                    style: _fs(_font,
                        size: 16,
                        weight: FontWeight.w700,
                        color: _textColor),
                  ),
                ),
                if (_service != null)
                  Text(
                    _service!.nombre,
                    style: _fs(_font, size: 12, color: _subColor),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          Divider(
              color: widget.dark
                  ? Colors.white12
                  : Colors.grey.shade200),

          // ── Content ──────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),

          // ── Confirm button ───────────────────────────────────────────
          if (_step == _Step.slots && _selectedSlot != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _confirm,
                  child: Text(
                    'Confirmar turno · ${_selectedSlot!.label}',
                    style: _fs(_font,
                        size: 15,
                        weight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _Step.service:
        return _buildServiceStep();
      case _Step.staff:
        return _buildStaffStep();
      case _Step.date:
        return _buildDateStep();
      case _Step.slots:
        return _buildSlotsStep();
    }
  }

  // ── Step: service ──────────────────────────────────────────────────────────

  Widget _buildServiceStep() {
    return Column(
      children: [
        for (final svc in widget.allServices)
          InkWell(
            onTap: () => setState(() {
              _service = svc;
              _step = _Step.staff;
            }),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.dark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: widget.dark
                        ? Colors.white12
                        : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(svc.nombre,
                            style: _fs(_font,
                                size: 15,
                                weight: FontWeight.w600,
                                color: _textColor)),
                        const SizedBox(height: 3),
                        Text('${svc.duracionMin} min',
                            style:
                                _fs(_font, size: 12, color: _subColor)),
                      ],
                    ),
                  ),
                  Text(
                    '\$${svc.precio.toStringAsFixed(0)}',
                    style: _fs(_font,
                        size: 16,
                        weight: FontWeight.w700,
                        color: _primary),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right,
                      color: _subColor, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Step: staff ────────────────────────────────────────────────────────────

  Widget _buildStaffStep() {
    final staffAsync =
        ref.watch(publicStaffProvider(widget.business.id));

    return staffAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('No se pudo cargar el equipo.',
          style: TextStyle(color: _subColor)),
      data: (staff) => Column(
        children: [
          // "Any member" option
          _StaffOption(
            label: 'Cualquier miembro disponible',
            subtitle: 'Te asignamos el próximo turno libre',
            icon: Icons.groups_outlined,
            color: _primary,
            dark: widget.dark,
            selected: _anyStaff,
            onTap: () => _selectStaff(any: true),
          ),
          const SizedBox(height: 8),
          if (staff.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No hay miembros del equipo disponibles.',
                  style: _fs(_font, size: 13, color: _subColor)),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final m in staff)
                  _StaffCard(
                    member: m,
                    primaryColor: _primary,
                    dark: widget.dark,
                    selected: _selectedStaff?.id == m.id,
                    fontFamily: _font,
                    onTap: () => _selectStaff(member: m),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Step: date ─────────────────────────────────────────────────────────────

  Widget _buildDateStep() {
    final today = DateTime.now();
    final dates = List.generate(
        14, (i) => DateTime(today.year, today.month, today.day + i));

    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const monthNames = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dates.map((d) {
        final isSelected = _selectedDate?.day == d.day &&
            _selectedDate?.month == d.month;
        final isToday = d.day == today.day && d.month == today.month;
        final label = isToday
            ? 'Hoy'
            : '${dayNames[d.weekday - 1]} ${d.day} ${monthNames[d.month - 1]}';

        return GestureDetector(
          onTap: () => _selectDate(d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? _primary
                  : (widget.dark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? _primary
                    : (widget.dark
                        ? Colors.white12
                        : Colors.grey.shade300),
              ),
            ),
            child: Text(
              label,
              style: _fs(_font,
                  size: 13,
                  weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : _textColor),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Step: slots ────────────────────────────────────────────────────────────

  Widget _buildSlotsStep() {
    if (_slotsFuture == null) return const SizedBox.shrink();

    return FutureBuilder<List<AvailabilitySlot>>(
      future: _slotsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ));
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No se pudieron cargar los turnos.',
              style: _fs(_font, size: 14, color: _subColor),
            ),
          );
        }
        final slots = snap.data ?? [];
        if (slots.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(Icons.event_busy_outlined,
                    size: 48,
                    color:
                        widget.dark ? Colors.white24 : Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No hay turnos disponibles para este día.',
                  textAlign: TextAlign.center,
                  style: _fs(_font, size: 14, color: _subColor),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _step = _Step.date;
                    _selectedSlot = null;
                  }),
                  child: Text('Elegir otra fecha',
                      style: _fs(_font, size: 13, color: _primary)),
                ),
              ],
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final selected = _selectedSlot?.inicio == slot.inicio;
            return GestureDetector(
              onTap: () => _selectSlot(slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? _primary
                      : (widget.dark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? _primary
                        : (widget.dark
                            ? Colors.white12
                            : Colors.grey.shade300),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  slot.label,
                  style: _fs(_font,
                      size: 14,
                      weight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected ? Colors.white : _textColor),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.logoUrl,
    required this.nombre,
    required this.color,
    this.size = 80,
    this.borderColor,
  });

  final String? logoUrl;
  final String nombre;
  final Color color;
  final double size;
  final Color? borderColor;

  String get _initials {
    final words = nombre.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 3)
            : Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl!.startsWith('http')
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Center(
                child: Text(_initials,
                    style: TextStyle(
                        color: color,
                        fontSize: size * 0.3,
                        fontWeight: FontWeight.w800)),
              ),
            )
          : Center(
              child: Text(_initials,
                  style: TextStyle(
                      color: color,
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w800)),
            ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.primaryColor,
    required this.fontFamily,
    required this.dark,
    required this.onBook,
  });

  final AgendaService service;
  final Color primaryColor;
  final String fontFamily;
  final bool dark;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? Colors.white : Colors.black87;
    final subColor = dark ? Colors.white54 : Colors.grey.shade600;
    final cardColor =
        dark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade50;
    final borderColor =
        dark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200;

    return InkWell(
      onTap: onBook,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.nombre,
                      style: _fs(fontFamily,
                          size: 15,
                          weight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 4),
                  Text('${service.duracionMin} min',
                      style: _fs(fontFamily, size: 13, color: subColor)),
                ],
              ),
            ),
            Text(
              '\$${service.precio.toStringAsFixed(0)}',
              style: _fs(fontFamily,
                  size: 16,
                  weight: FontWeight.w700,
                  color: primaryColor),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: subColor),
          ],
        ),
      ),
    );
  }
}

class _StaffOption extends StatelessWidget {
  const _StaffOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.dark,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool dark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : (dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : (dark ? Colors.white12 : Colors.grey.shade200),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: dark ? Colors.white : Colors.black87)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: dark
                              ? Colors.white54
                              : Colors.grey.shade600)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.member,
    required this.primaryColor,
    required this.dark,
    required this.selected,
    required this.fontFamily,
    required this.onTap,
  });

  final StaffMember member;
  final Color primaryColor;
  final bool dark;
  final bool selected;
  final String fontFamily;
  final VoidCallback onTap;

  String get _initials {
    final words = member.nombre.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return member.nombre.substring(0, member.nombre.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? Colors.white : Colors.black87;
    final subColor = dark ? Colors.white54 : Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 108,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.12)
              : (dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? primaryColor
                : (dark ? Colors.white12 : Colors.grey.shade200),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.12),
                border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: member.avatarUrl != null
                  ? Image.network(
                      member.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Center(
                        child: Text(_initials,
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                      ),
                    )
                  : Center(
                      child: Text(_initials,
                          style: TextStyle(
                              color: primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              member.nombre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _fs(fontFamily,
                  size: 12,
                  weight: FontWeight.w600,
                  color: textColor),
            ),
            if (member.rol != null) ...[
              const SizedBox(height: 2),
              Text(
                member.rol!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _fs(fontFamily, size: 10, color: subColor),
              ),
            ],
            if (selected) ...[
              const SizedBox(height: 4),
              Icon(Icons.check_circle, color: primaryColor, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Font helper
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _fs(String family, {double? size, FontWeight? weight, Color? color}) {
  try {
    return GoogleFonts.getFont(family,
        fontSize: size, fontWeight: weight, color: color);
  } catch (_) {
    return TextStyle(
        fontFamily: family, fontSize: size, fontWeight: weight, color: color);
  }
}

class _ClientPayload {
  const _ClientPayload({required this.nombre, this.email, this.telefono});
  final String nombre;
  final String? email;
  final String? telefono;
}
