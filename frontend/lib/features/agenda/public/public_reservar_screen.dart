import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/availability_slot.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import 'public_reservar_layout.dart';

enum _BookingStep { service, staff, date, slots }

/// Reserva pública unificada: /reservar/:slug (mismo look que el sheet del detalle).
class PublicReservarScreen extends ConsumerStatefulWidget {
  const PublicReservarScreen({
    super.key,
    required this.slug,
    this.companySlug,
  });

  final String slug;
  final String? companySlug;

  @override
  ConsumerState<PublicReservarScreen> createState() =>
      _PublicReservarScreenState();
}

class _PublicReservarScreenState extends ConsumerState<PublicReservarScreen> {
  _BookingStep _step = _BookingStep.service;
  AgendaService? _service;
  bool _anyStaff = false;
  StaffMember? _selectedStaff;
  DateTime? _selectedDate;
  AvailabilitySlot? _selectedSlot;
  Future<List<AvailabilitySlot>>? _slotsFuture;

  void _goBack(PublicReservarTheme theme, Business business) {
    switch (_step) {
      case _BookingStep.service:
        if (widget.companySlug != null && widget.companySlug!.isNotEmpty) {
          context.go('/reservar?company=${widget.companySlug}');
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      case _BookingStep.staff:
        setState(() => _step = _BookingStep.service);
      case _BookingStep.date:
        setState(() {
          _step = _BookingStep.staff;
          _selectedDate = null;
          _selectedSlot = null;
        });
      case _BookingStep.slots:
        setState(() {
          _step = _BookingStep.date;
          _selectedSlot = null;
        });
    }
  }

  String _stepTitle(_BookingStep step) {
    switch (step) {
      case _BookingStep.service:
        return 'Elegí un servicio';
      case _BookingStep.staff:
        return 'Elegí un profesional';
      case _BookingStep.date:
        return 'Elegí una fecha';
      case _BookingStep.slots:
        return 'Elegí un horario';
    }
  }

  void _selectDate(DateTime date, PublicReservarTheme theme) {
    final staffId = _anyStaff ? null : _selectedStaff?.id;
    final key = (
      slug: widget.slug,
      serviceId: _service!.id,
      staffMemberId: staffId,
      date:
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    );
    setState(() {
      _selectedDate = date;
      _selectedSlot = null;
      _step = _BookingStep.slots;
      _slotsFuture = ref.read(availabilityBySlugProvider(key).future);
    });
  }

  Future<void> _confirm(Business business, PublicReservarTheme theme) async {
    final svc = _service;
    final slot = _selectedSlot;
    if (svc == null || slot == null) return;

    final payload = await _askClientData(theme);
    if (payload == null) return;

    try {
      final api = ref.read(agendaApiServiceProvider);
      final client = await api.createClient(
        businessId: business.id,
        nombre: payload.nombre,
        email: payload.email,
        telefono: payload.telefono,
      );
      await api.publicCreateBooking(
        businessId: business.id,
        serviceId: svc.id,
        staffMemberId: _anyStaff ? null : _selectedStaff?.id,
        fechaHoraInicio: slot.inicio,
        clientId: client.id,
      );

      if (!mounted) return;
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
          backgroundColor: theme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      if (widget.companySlug != null && widget.companySlug!.isNotEmpty) {
        context.go('/reservar?company=${widget.companySlug}');
      } else {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo solicitar el turno: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<_ClientPayload?> _askClientData(PublicReservarTheme theme) async {
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
            style: FilledButton.styleFrom(backgroundColor: theme.primary),
            onPressed: () {
              final nombre = nombreCtrl.text.trim();
              if (nombre.isEmpty) return;
              Navigator.of(ctx).pop(_ClientPayload(
                nombre: nombre,
                email: emailCtrl.text.trim().isEmpty
                    ? null
                    : emailCtrl.text.trim(),
                telefono: telCtrl.text.trim().isEmpty
                    ? null
                    : telCtrl.text.trim(),
              ));
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(publicBusinessBySlugProvider(widget.slug));
    final servicesAsync =
        ref.watch(publicBusinessServicesBySlugProvider(widget.slug));

    return businessAsync.when(
      loading: () => const Scaffold(body: AgendaLoadingView()),
      error: (e, _) => Scaffold(
        body: AgendaErrorView(
          message: 'No se pudo cargar el negocio: $e',
          onRetry: () => ref.refresh(publicBusinessBySlugProvider(widget.slug)),
        ),
      ),
      data: (business) {
        final theme = PublicReservarTheme.fromHex(
          colorPrimario: business.colorPrimario,
          colorFondo: business.colorFondo,
          fontFamily: business.fontFamily,
          logoUrl: business.logoUrl,
        );

        return PublicReservarShell(
          theme: theme,
          brandTitle: business.nombre,
          subtitle: business.descripcion,
          sectionTitle: _stepTitle(_step),
          onBack: () => _goBack(theme, business),
          footer: publicReservarFooterLink(
            theme: theme,
            onTap: () => context.go('/agenda/me/bookings'),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStep(
                    business,
                    theme,
                    servicesAsync,
                  ),
                ),
              ),
              if (_step == _BookingStep.slots && _selectedSlot != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _confirm(business, theme),
                      child: Text(
                        'Confirmar turno · ${_selectedSlot!.label}',
                        style: theme.textStyle(
                          size: 15,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep(
    Business business,
    PublicReservarTheme theme,
    AsyncValue<List<AgendaService>> servicesAsync,
  ) {
    switch (_step) {
      case _BookingStep.service:
        return servicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('No se pudieron cargar los servicios.',
              style: theme.textStyle(color: theme.textSub)),
          data: (list) => list.isEmpty
              ? Text('Este negocio todavía no publicó servicios.',
                  style: theme.textStyle(color: theme.textSub))
              : Column(
                  children: [
                    for (final svc in list)
                      _ServiceRow(
                        theme: theme,
                        service: svc,
                        onTap: () => setState(() {
                          _service = svc;
                          _step = _BookingStep.staff;
                        }),
                      ),
                  ],
                ),
        );
      case _BookingStep.staff:
        return ref.watch(publicStaffBySlugProvider(widget.slug)).when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('No se pudo cargar el equipo.',
                  style: theme.textStyle(color: theme.textSub)),
              data: (staff) => Column(
                children: [
                  _StaffAnyTile(
                    theme: theme,
                    selected: _anyStaff,
                    onTap: () => setState(() {
                      _anyStaff = true;
                      _selectedStaff = null;
                      _step = _BookingStep.date;
                    }),
                  ),
                  const SizedBox(height: 8),
                  if (staff.isEmpty)
                    Text('No hay profesionales disponibles.',
                        style: theme.textStyle(
                            size: 13, color: theme.textSub))
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final m in staff)
                          _StaffChip(
                            theme: theme,
                            member: m,
                            selected: _selectedStaff?.id == m.id,
                            onTap: () => setState(() {
                              _anyStaff = false;
                              _selectedStaff = m;
                              _step = _BookingStep.date;
                            }),
                          ),
                      ],
                    ),
                ],
              ),
            );
      case _BookingStep.date:
        return _DatePicker(
          theme: theme,
          selectedDate: _selectedDate,
          onSelect: (d) => _selectDate(d, theme),
        );
      case _BookingStep.slots:
        return _SlotsPicker(
          theme: theme,
          slotsFuture: _slotsFuture,
          selected: _selectedSlot,
          onSelect: (s) => setState(() => _selectedSlot = s),
          onPickOtherDate: () => setState(() {
            _step = _BookingStep.date;
            _selectedSlot = null;
          }),
        );
    }
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.theme,
    required this.service,
    required this.onTap,
  });

  final PublicReservarTheme theme;
  final AgendaService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.cardFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.nombre,
                        style: t.textStyle(
                            size: 15, weight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text('${service.duracionMin} min',
                        style: t.textStyle(size: 12, color: t.textSub)),
                  ],
                ),
              ),
              Text(
                '\$${service.precio.toStringAsFixed(0)}',
                style: t.textStyle(
                    size: 16,
                    weight: FontWeight.w700,
                    color: t.primary),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: t.textSub, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffAnyTile extends StatelessWidget {
  const _StaffAnyTile({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final PublicReservarTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? t.primary.withValues(alpha: 0.1) : t.cardFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? t.primary : t.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.groups_outlined, color: t.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cualquier profesional disponible',
                      style: t.textStyle(
                          size: 14, weight: FontWeight.w600)),
                  Text('Te asignamos el próximo turno libre',
                      style: t.textStyle(size: 12, color: t.textSub)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: t.primary),
          ],
        ),
      ),
    );
  }
}

class _StaffChip extends StatelessWidget {
  const _StaffChip({
    required this.theme,
    required this.member,
    required this.selected,
    required this.onTap,
  });

  final PublicReservarTheme theme;
  final StaffMember member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final initials = member.nombre.trim().split(RegExp(r'\s+'));
    final label = initials.length >= 2
        ? '${initials[0][0]}${initials[1][0]}'.toUpperCase()
        : member.nombre.substring(0, 1).toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? t.primary.withValues(alpha: 0.1) : t.cardFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? t.primary : t.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: t.primary.withValues(alpha: 0.12),
              backgroundImage: member.avatarUrl != null
                  ? NetworkImage(member.avatarUrl!)
                  : null,
              child: member.avatarUrl == null
                  ? Text(label,
                      style: TextStyle(
                          color: t.primary, fontWeight: FontWeight.w800))
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              member.nombre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.textStyle(size: 12, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({
    required this.theme,
    this.selectedDate,
    required this.onSelect,
  });

  final PublicReservarTheme theme;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final today = DateTime.now();
    final dates =
        List.generate(14, (i) => DateTime(today.year, today.month, today.day + i));
    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const monthNames = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dates.map((d) {
        final isToday = d.day == today.day && d.month == today.month;
        final isSelected = selectedDate != null &&
            selectedDate!.day == d.day &&
            selectedDate!.month == d.month &&
            selectedDate!.year == d.year;
        final label = isToday
            ? 'Hoy'
            : '${dayNames[d.weekday - 1]} ${d.day} ${monthNames[d.month - 1]}';
        return GestureDetector(
          onTap: () => onSelect(d),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? t.primary : t.cardFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? t.primary : t.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: t.textStyle(
                size: 13,
                weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : t.text,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SlotsPicker extends StatelessWidget {
  const _SlotsPicker({
    required this.theme,
    required this.slotsFuture,
    required this.selected,
    required this.onSelect,
    required this.onPickOtherDate,
  });

  final PublicReservarTheme theme;
  final Future<List<AvailabilitySlot>>? slotsFuture;
  final AvailabilitySlot? selected;
  final ValueChanged<AvailabilitySlot> onSelect;
  final VoidCallback onPickOtherDate;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    if (slotsFuture == null) return const SizedBox.shrink();

    return FutureBuilder<List<AvailabilitySlot>>(
      future: slotsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Text('No se pudieron cargar los turnos.',
              style: t.textStyle(color: t.textSub));
        }
        final slots = snap.data ?? [];
        if (slots.isEmpty) {
          return Column(
            children: [
              Icon(Icons.event_busy_outlined,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'No hay turnos disponibles para este día.',
                textAlign: TextAlign.center,
                style: t.textStyle(size: 14, color: t.textSub),
              ),
              TextButton(
                onPressed: onPickOtherDate,
                child: Text('Elegir otra fecha',
                    style: t.textStyle(size: 13, color: t.primary)),
              ),
            ],
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSel = selected?.inicio == slot.inicio;
            return GestureDetector(
              onTap: () => onSelect(slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isSel ? t.primary : t.cardFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel ? t.primary : t.cardBorder,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Text(
                  slot.label,
                  style: t.textStyle(
                    size: 14,
                    weight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? Colors.white : t.text,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ClientPayload {
  const _ClientPayload({required this.nombre, this.email, this.telefono});
  final String nombre;
  final String? email;
  final String? telefono;
}
