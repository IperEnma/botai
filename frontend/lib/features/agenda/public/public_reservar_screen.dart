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

enum _BookingStep { service, staff, date, slots, review, contact }

const int _kBookingTotalSteps = 6;

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
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _contactFormKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

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
      case _BookingStep.review:
        setState(() => _step = _BookingStep.slots);
      case _BookingStep.contact:
        setState(() => _step = _BookingStep.review);
    }
  }

  int _stepIndex(_BookingStep step) {
    switch (step) {
      case _BookingStep.service:
        return 1;
      case _BookingStep.staff:
        return 2;
      case _BookingStep.date:
        return 3;
      case _BookingStep.slots:
        return 4;
      case _BookingStep.review:
        return 5;
      case _BookingStep.contact:
        return 6;
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
      case _BookingStep.review:
        return 'Revisá tu reserva';
      case _BookingStep.contact:
        return 'Tus datos de contacto';
    }
  }

  String _stepProgressLabel(_BookingStep step) {
    switch (step) {
      case _BookingStep.service:
        return 'Servicio';
      case _BookingStep.staff:
        return 'Profesional';
      case _BookingStep.date:
        return 'Fecha';
      case _BookingStep.slots:
        return 'Horario';
      case _BookingStep.review:
        return 'Resumen';
      case _BookingStep.contact:
        return 'Contacto';
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

  void _goToReview() {
    if (_service == null || _selectedSlot == null || _selectedDate == null) return;
    setState(() => _step = _BookingStep.review);
  }

  void _goToContact() {
    setState(() => _step = _BookingStep.contact);
  }

  Future<void> _confirm(Business business, PublicReservarTheme theme) async {
    final svc = _service;
    final slot = _selectedSlot;
    if (svc == null || slot == null) return;
    if (!_contactFormKey.currentState!.validate()) return;

    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final telefono = _telCtrl.text.trim();

    setState(() => _submitting = true);
    try {
      final api = ref.read(agendaApiServiceProvider);
      final client = await api.createClient(
        businessId: business.id,
        nombre: nombre,
        email: email.isEmpty ? null : email,
        telefono: telefono.isEmpty ? null : telefono,
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
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formattedSelectedDate() {
    final d = _selectedDate;
    if (d == null) return '—';
    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const monthNames = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final today = DateTime.now();
    final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
    if (isToday) return 'Hoy';
    return '${dayNames[d.weekday - 1]} ${d.day} ${monthNames[d.month - 1]} ${d.year}';
  }

  String _staffSummaryLabel() {
    if (_anyStaff) return 'Cualquier profesional disponible';
    return _selectedStaff?.nombre ?? '—';
  }

  Widget? _buildStepFooter(Business business, PublicReservarTheme theme) {
    switch (_step) {
      case _BookingStep.slots:
        if (_selectedSlot == null) return null;
        return _PrimaryFooterButton(
          theme: theme,
          label: 'Continuar',
          onPressed: _goToReview,
        );
      case _BookingStep.review:
        return _PrimaryFooterButton(
          theme: theme,
          label: 'Continuar con tus datos',
          onPressed: _goToContact,
        );
      case _BookingStep.contact:
        return _PrimaryFooterButton(
          theme: theme,
          label: 'Confirmar reserva',
          loading: _submitting,
          onPressed: _submitting ? null : () => _confirm(business, theme),
        );
      default:
        return null;
    }
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
          progressCurrent: _stepIndex(_step),
          progressTotal: _kBookingTotalSteps,
          progressStepLabel: _stepProgressLabel(_step),
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
              Builder(
                builder: (context) {
                  final footer = _buildStepFooter(business, theme);
                  if (footer == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: footer,
                  );
                },
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
      case _BookingStep.review:
        return _BookingReview(
          theme: theme,
          businessName: business.nombre,
          service: _service!,
          staffLabel: _staffSummaryLabel(),
          dateLabel: _formattedSelectedDate(),
          slotLabel: _selectedSlot?.label ?? '—',
        );
      case _BookingStep.contact:
        return _ContactStep(
          theme: theme,
          businessName: business.nombre,
          formKey: _contactFormKey,
          nombreCtrl: _nombreCtrl,
          emailCtrl: _emailCtrl,
          telCtrl: _telCtrl,
        );
    }
  }
}

class _PrimaryFooterButton extends StatelessWidget {
  const _PrimaryFooterButton({
    required this.theme,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final PublicReservarTheme theme;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: theme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: theme.textStyle(
                  size: 15,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _BookingReview extends StatelessWidget {
  const _BookingReview({
    required this.theme,
    required this.businessName,
    required this.service,
    required this.staffLabel,
    required this.dateLabel,
    required this.slotLabel,
  });

  final PublicReservarTheme theme;
  final String businessName;
  final AgendaService service;
  final String staffLabel;
  final String dateLabel;
  final String slotLabel;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Comprobá que todo esté correcto antes de continuar.',
          style: t.textStyle(size: 14, color: t.textSub),
        ),
        const SizedBox(height: 16),
        _ReviewRow(theme: t, icon: Icons.storefront_outlined, label: 'Negocio', value: businessName),
        _ReviewRow(theme: t, icon: Icons.spa_outlined, label: 'Servicio', value: service.nombre),
        _ReviewRow(
          theme: t,
          icon: Icons.schedule_outlined,
          label: 'Duración',
          value: '${service.duracionMin} min · \$${service.precio.toStringAsFixed(0)}',
        ),
        _ReviewRow(theme: t, icon: Icons.person_outline, label: 'Profesional', value: staffLabel),
        _ReviewRow(theme: t, icon: Icons.calendar_today_outlined, label: 'Fecha', value: dateLabel),
        _ReviewRow(theme: t, icon: Icons.access_time, label: 'Horario', value: slotLabel),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: t.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'En el siguiente paso te pediremos nombre y, si querés, email o teléfono para gestionar esta reserva.',
                  style: t.textStyle(size: 13, color: t.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
  });

  final PublicReservarTheme theme;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: t.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.textStyle(size: 12, color: t.textSub)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: t.textStyle(size: 15, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactStep extends StatelessWidget {
  const _ContactStep({
    required this.theme,
    required this.businessName,
    required this.formKey,
    required this.nombreCtrl,
    required this.emailCtrl,
    required this.telCtrl,
  });

  final PublicReservarTheme theme;
  final String businessName;
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController telCtrl;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Necesitamos algunos datos para registrar tu turno con $businessName. '
            'El nombre es obligatorio; email y teléfono son opcionales pero nos ayudan a contactarte.',
            style: t.textStyle(size: 14, color: t.textSub),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: nombreCtrl,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nombre completo',
              hintText: 'Ej. María González',
              helperText: 'Obligatorio · aparece en tu reserva',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Ingresá tu nombre para continuar';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Correo electrónico (opcional)',
              hintText: 'tu@email.com',
              helperText: 'Para enviarte confirmación o recordatorios',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: telCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Teléfono (opcional)',
              hintText: 'Ej. 09 123 456',
              helperText: 'Por si el negocio debe avisarte un cambio',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.cardFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 18, color: t.textSub),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Usamos estos datos solo para gestionar tu reserva con este negocio. '
                    'No los vendemos ni los compartimos con terceros ajenos al turno.',
                    style: t.textStyle(size: 12, color: t.textSub),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
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

