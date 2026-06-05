import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/agenda_phone.dart';
import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/booking.dart';
import '../../../models/agenda/availability_slot.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/business_hours.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../models/agenda/public_client_profile.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../providers/agenda/public/public_client_session_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../../../widgets/agenda_phone_field.dart';
import 'public_booking_hours.dart';
import 'public_reservar_layout.dart';

enum _BookingStep { service, staff, date, slots, review, contact, verifyCode, confirmed }

const int _kBookingTotalStepsWithStaff = 7;
const int _kBookingTotalStepsGeneral = 6;

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
  final _codeCtrl = TextEditingController();
  final _contactFormKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _otpError;
  String? _otpHint;
  StoredPublicClientSession? _session;
  bool _sessionRestored = false;
  String? _confirmedServiceName;
  String? _confirmedSlotLabel;
  String? _confirmedDateLabel;
  BookingEstado? _confirmedEstado;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  bool _usesStaffStep(AgendaService? svc) => svc?.requiresStaffSelection ?? false;

  String? get _effectiveStaffId {
    if (!_usesStaffStep(_service)) return null;
    return _anyStaff ? null : _selectedStaff?.id;
  }

  int _progressTotal(AgendaService? svc) =>
      _usesStaffStep(svc) ? _kBookingTotalStepsWithStaff : _kBookingTotalStepsGeneral;

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
          _step = _usesStaffStep(_service)
              ? _BookingStep.staff
              : _BookingStep.service;
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
      case _BookingStep.verifyCode:
        setState(() => _step = _BookingStep.contact);
      case _BookingStep.confirmed:
        break;
    }
  }

  int _stepIndex(_BookingStep step) {
    final withStaff = _usesStaffStep(_service);
    switch (step) {
      case _BookingStep.service:
        return 1;
      case _BookingStep.staff:
        return withStaff ? 2 : 1;
      case _BookingStep.date:
        return withStaff ? 3 : 2;
      case _BookingStep.slots:
        return withStaff ? 4 : 3;
      case _BookingStep.review:
        return withStaff ? 5 : 4;
      case _BookingStep.contact:
        return withStaff ? 6 : 5;
      case _BookingStep.verifyCode:
        return withStaff ? 7 : 6;
      case _BookingStep.confirmed:
        return withStaff ? 7 : 6;
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
      case _BookingStep.verifyCode:
        return 'Verificá tu teléfono';
      case _BookingStep.confirmed:
        return 'Confirmación';
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
      case _BookingStep.verifyCode:
        return 'Código';
      case _BookingStep.confirmed:
        return 'Listo';
    }
  }

  String? _stepSubtitle(_BookingStep step) {
    switch (step) {
      case _BookingStep.review:
        return 'Comprobá que todo esté correcto antes de continuar.';
      case _BookingStep.contact:
        return 'Te enviaremos un código por WhatsApp para confirmar que el teléfono es tuyo.';
      case _BookingStep.verifyCode:
        return _otpHint ?? 'Ingresá el código de 6 dígitos que recibiste por WhatsApp.';
      default:
        return null;
    }
  }

  void _selectDate(DateTime date, PublicReservarTheme theme) {
    final staffId = _effectiveStaffId;
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

  Widget _buildDatePicker(PublicReservarTheme theme) {
    final hoursAsync = ref.watch(publicHoursBySlugProvider(widget.slug));
    return hoursAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _DatePicker(
        theme: theme,
        selectedDate: _selectedDate,
        hours: const [],
        onSelect: (d) => _selectDate(d, theme),
      ),
      data: (hours) => _DatePicker(
        theme: theme,
        selectedDate: _selectedDate,
        hours: hours,
        onSelect: (d) => _selectDate(d, theme),
      ),
    );
  }

  void _goToReview() {
    if (_service == null || _selectedSlot == null || _selectedDate == null) return;
    setState(() => _step = _BookingStep.review);
  }

  void _goToContact() {
    setState(() => _step = _BookingStep.contact);
  }

  String _misReservasPath() {
    final base = '/reservar/${widget.slug}/mis-reservas';
    final company = widget.companySlug;
    if (company != null && company.isNotEmpty) {
      return '$base?company=$company';
    }
    return base;
  }

  String _explorarMasPath() => '/agenda/search';

  Future<void> _restoreSession(Business business) async {
    final stored =
        await ref.read(publicClientSessionStorageProvider).load(widget.slug);
    if (stored == null || stored.businessId != business.id) return;
    if (!mounted) return;
    setState(() {
      _session = stored;
      _telCtrl.text = stored.phone;
      if (stored.nombre != null && !stored.needsName) {
        _nombreCtrl.text = stored.nombre!;
      }
    });
  }

  Future<void> _persistSession(
    VerifyPublicPhoneResult result,
    Business business,
  ) async {
    final telefono = normalizeAgendaPhoneDigits(_telCtrl.text);
    final session = StoredPublicClientSession.fresh(
      token: result.clientSessionToken,
      businessId: business.id,
      phone: telefono,
      needsName: result.client.needsName,
      nombre: result.client.needsName ? null : result.client.nombre,
    );
    await ref.read(publicClientSessionStorageProvider).save(widget.slug, session);
    ref.invalidate(publicClientSessionProvider(widget.slug));
    if (!mounted) return;
    setState(() => _session = session);
  }

  Future<void> _submitBookingWithSession(
    Business business,
    PublicReservarTheme theme,
  ) async {
    final svc = _service;
    final slot = _selectedSlot;
    final session = _session;
    if (svc == null || slot == null || session == null) return;

    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (session.needsName && nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ingresá tu nombre para continuar.',
            style: theme.textStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(agendaApiServiceProvider);
      final booking = await api.publicCreateBooking(
        businessId: business.id,
        serviceId: svc.id,
        staffMemberId: _effectiveStaffId,
        fechaHoraInicio: slot.inicio,
        nombreCliente: session.needsName ? nombre : (nombre.isEmpty ? null : nombre),
        emailCliente: email.isEmpty ? null : email,
        telefonoCliente: session.phone,
        clientSessionToken: session.token,
      );
      if (session.needsName && nombre.isNotEmpty) {
        final updated = session.copyWith(needsName: false, nombre: nombre);
        await ref.read(publicClientSessionStorageProvider).save(widget.slug, updated);
        if (mounted) setState(() => _session = updated);
      }
      if (!mounted) return;
      setState(() {
        _confirmedServiceName = svc.nombre;
        _confirmedSlotLabel = slot.label;
        _confirmedDateLabel = _formattedSelectedDate();
        _confirmedEstado = booking.estado;
        _step = _BookingStep.confirmed;
      });
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

  Future<void> _sendOtp(Business business, PublicReservarTheme theme) async {
    if (!_contactFormKey.currentState!.validate()) return;
    final telefono = normalizeAgendaPhoneDigits(_telCtrl.text);
    if (!isValidAgendaPhone(telefono)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ingresá un teléfono válido con código de país.',
            style: theme.textStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _otpError = null;
    });
    try {
      final api = ref.read(agendaApiServiceProvider);
      final result = await api.sendPublicPhoneVerification(
        businessId: business.id,
        telefono: telefono,
      );
      if (!mounted) return;
      setState(() {
        _otpHint = result.message;
        _step = _BookingStep.verifyCode;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar el código: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirm(Business business, PublicReservarTheme theme) async {
    final svc = _service;
    final slot = _selectedSlot;
    if (svc == null || slot == null) return;

    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final telefono = normalizeAgendaPhoneDigits(_telCtrl.text);
    if (!isValidAgendaPhone(telefono)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ingresá un teléfono válido con código de país.',
            style: theme.textStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _otpError = 'Ingresá el código de WhatsApp.');
      return;
    }

    setState(() {
      _submitting = true;
      _otpError = null;
    });
    try {
      final api = ref.read(agendaApiServiceProvider);
      final result = await api.verifyPublicPhoneCode(
        businessId: business.id,
        telefono: telefono,
        code: code,
      );
      await _persistSession(result, business);
      final booking = await api.publicCreateBooking(
        businessId: business.id,
        serviceId: svc.id,
        staffMemberId: _effectiveStaffId,
        fechaHoraInicio: slot.inicio,
        nombreCliente: nombre,
        emailCliente: email.isEmpty ? null : email,
        telefonoCliente: telefono,
        clientSessionToken: result.clientSessionToken,
      );
      if (result.client.needsName && nombre.isNotEmpty) {
        final updated = _session!.copyWith(needsName: false, nombre: nombre);
        await ref.read(publicClientSessionStorageProvider).save(widget.slug, updated);
        if (mounted) setState(() => _session = updated);
      }

      if (!mounted) return;
      setState(() {
        _confirmedServiceName = svc.nombre;
        _confirmedSlotLabel = slot.label;
        _confirmedDateLabel = _formattedSelectedDate();
        _confirmedEstado = booking.estado;
        _step = _BookingStep.confirmed;
        _submitting = false;
      });
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
    if (!_usesStaffStep(_service)) return 'Agenda del negocio';
    if (_anyStaff) return 'Cualquiera disponible';
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
        if (_session != null && !_session!.needsName) {
          return _PrimaryFooterButton(
            theme: theme,
            label: 'Confirmar reserva',
            loading: _submitting,
            onPressed:
                _submitting ? null : () => _submitBookingWithSession(business, theme),
          );
        }
        return _PrimaryFooterButton(
          theme: theme,
          label: 'Continuar con tus datos',
          onPressed: _goToContact,
        );
      case _BookingStep.contact:
        if (_session != null && _session!.needsName) {
          return _PrimaryFooterButton(
            theme: theme,
            label: 'Confirmar reserva',
            loading: _submitting,
            onPressed: _submitting
                ? null
                : () {
                    if (!_contactFormKey.currentState!.validate()) return;
                    _submitBookingWithSession(business, theme);
                  },
          );
        }
        return _PrimaryFooterButton(
          theme: theme,
          label: 'Enviar código por WhatsApp',
          loading: _submitting,
          onPressed: _submitting ? null : () => _sendOtp(business, theme),
        );
      case _BookingStep.verifyCode:
        return _PrimaryFooterButton(
          theme: theme,
          label: 'Confirmar reserva',
          loading: _submitting,
          onPressed: _submitting ? null : () => _confirm(business, theme),
        );
      case _BookingStep.confirmed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PrimaryFooterButton(
              theme: theme,
              label: 'Ver mis reservas',
              onPressed: () => context.go(_misReservasPath()),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: theme.primary),
              ),
              icon: Icon(Icons.explore_outlined, color: theme.primary, size: 20),
              onPressed: () => context.go(_explorarMasPath()),
              label: Text(
                'Explorar más',
                style: theme.textStyle(color: theme.primary, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: theme.primary),
              ),
              onPressed: () {
                setState(() {
                  _step = _BookingStep.service;
                  _service = null;
                  _selectedDate = null;
                  _selectedSlot = null;
                  _slotsFuture = null;
                  _confirmedServiceName = null;
                  _confirmedSlotLabel = null;
                  _confirmedDateLabel = null;
                  _confirmedEstado = null;
                  _codeCtrl.clear();
                  _otpError = null;
                  _otpHint = null;
                });
              },
              child: Text(
                'Reservar otro turno',
                style: theme.textStyle(color: theme.primary, weight: FontWeight.w600),
              ),
            ),
          ],
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

        final isConfirmed = _step == _BookingStep.confirmed;

        if (!_sessionRestored) {
          _sessionRestored = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _restoreSession(business),
          );
        }

        return PublicReservarShell(
          theme: theme,
          brandTitle: business.nombre,
          progressCurrent: isConfirmed ? _progressTotal(_service) : _stepIndex(_step),
          progressTotal: _progressTotal(_service),
          progressStepLabel: isConfirmed ? 'Confirmación' : _stepProgressLabel(_step),
          onBack: isConfirmed ? null : () => _goBack(theme, business),
          footer: isConfirmed
              ? null
              : publicReservarFooterLink(
                  theme: theme,
                  onTap: () => context.go(_misReservasPath()),
                ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_step == _BookingStep.service)
                        publicReservarScrollBrandIntro(
                          theme: theme,
                          subtitle: business.descripcion,
                        ),
                      if (_step != _BookingStep.confirmed)
                        publicReservarScrollSectionTitle(
                          theme: theme,
                          title: _stepTitle(_step),
                          subtitle: _stepSubtitle(_step),
                        ),
                      _buildStep(
                        business,
                        theme,
                        servicesAsync,
                      ),
                    ],
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
                          _anyStaff = !svc.requiresStaffSelection;
                          _selectedStaff = null;
                          _selectedDate = null;
                          _selectedSlot = null;
                          _step = svc.requiresStaffSelection
                              ? _BookingStep.staff
                              : _BookingStep.date;
                        }),
                      ),
                  ],
                ),
        );
      case _BookingStep.staff:
        if (!_usesStaffStep(_service)) {
          return _buildDatePicker(theme);
        }
        return ref.watch(publicStaffBySlugProvider(widget.slug)).when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('No se pudo cargar el equipo.',
                  style: theme.textStyle(color: theme.textSub)),
              data: (allStaff) {
                final svcId = _service?.id;
                final staff = allStaff
                    .where((m) =>
                        m.activo &&
                        (svcId == null ||
                            m.serviceIds.isEmpty ||
                            m.serviceIds.contains(svcId)))
                    .toList();
                return Column(
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
              );
              },
            );
      case _BookingStep.date:
        return _buildDatePicker(theme);
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
          service: _service!,
          staffLabel: _staffSummaryLabel(),
          dateLabel: _formattedSelectedDate(),
          slotLabel: _selectedSlot?.label ?? '—',
          showStaffRow: _usesStaffStep(_service),
        );
      case _BookingStep.contact:
        return _ContactStep(
          theme: theme,
          formKey: _contactFormKey,
          nombreCtrl: _nombreCtrl,
          emailCtrl: _emailCtrl,
          telCtrl: _telCtrl,
          phoneReadOnly: _session != null,
          requireName: _session == null || _session!.needsName,
        );
      case _BookingStep.verifyCode:
        return _VerifyCodeStep(
          theme: theme,
          codeCtrl: _codeCtrl,
          phone: normalizeAgendaPhoneDigits(_telCtrl.text),
          error: _otpError,
          hint: _otpHint,
        );
      case _BookingStep.confirmed:
        return _BookingConfirmedStep(
          theme: theme,
          businessName: business.nombre,
          serviceName: _confirmedServiceName ?? '—',
          dateLabel: _confirmedDateLabel ?? '—',
          slotLabel: _confirmedSlotLabel ?? '—',
          estado: _confirmedEstado ?? BookingEstado.pendiente,
        );
    }
  }
}

class _BookingConfirmedStep extends StatelessWidget {
  const _BookingConfirmedStep({
    required this.theme,
    required this.businessName,
    required this.serviceName,
    required this.dateLabel,
    required this.slotLabel,
    required this.estado,
  });

  final PublicReservarTheme theme;
  final String businessName;
  final String serviceName;
  final String dateLabel;
  final String slotLabel;
  final BookingEstado estado;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final isConfirmed = estado == BookingEstado.confirmada;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.check_circle_rounded, size: 72, color: t.primary),
        const SizedBox(height: 20),
        Text(
          isConfirmed ? '¡Turno confirmado!' : '¡Reserva solicitada!',
          textAlign: TextAlign.center,
          style: t.textStyle(
            size: 24,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isConfirmed
              ? 'Tu turno en $businessName quedó confirmado. Te esperamos.'
              : 'Tu solicitud fue enviada a $businessName. Te avisaremos cuando la confirmen.',
          textAlign: TextAlign.center,
          style: t.textStyle(color: t.textSub, size: 15),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: t.cardFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _confirmRow(t, 'Servicio', serviceName),
              const SizedBox(height: 10),
              _confirmRow(t, 'Fecha', dateLabel),
              const SizedBox(height: 10),
              _confirmRow(t, 'Horario', slotLabel),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Guardá este número de WhatsApp: con el mismo teléfono podés consultar tus citas por el bot.',
          textAlign: TextAlign.center,
          style: t.textStyle(color: t.textSub, size: 13),
        ),
      ],
    );
  }

  Widget _confirmRow(PublicReservarTheme t, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: t.textStyle(
              color: t.textSub,
              size: 13,
              weight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: t.textStyle(size: 15, weight: FontWeight.w600),
          ),
        ),
      ],
    );
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
    required this.service,
    required this.staffLabel,
    required this.dateLabel,
    required this.slotLabel,
    this.showStaffRow = true,
  });

  final PublicReservarTheme theme;
  final AgendaService service;
  final String staffLabel;
  final String dateLabel;
  final String slotLabel;
  final bool showStaffRow;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        children: [
          _ReviewRow(theme: t, icon: Icons.spa_outlined, label: 'Servicio', value: service.nombre),
          _ReviewRow(
            theme: t,
            icon: Icons.schedule_outlined,
            label: 'Duración',
            value: '${service.duracionMin} min · \$${service.precio.toStringAsFixed(0)}',
          ),
          if (showStaffRow)
            _ReviewRow(
                theme: t,
                icon: Icons.person_outline,
                label: 'Profesional',
                value: staffLabel),
          _ReviewRow(theme: t, icon: Icons.calendar_today_outlined, label: 'Fecha', value: dateLabel),
          _ReviewRow(theme: t, icon: Icons.access_time, label: 'Horario', value: slotLabel),
        ],
      ),
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

class _VerifyCodeStep extends StatelessWidget {
  const _VerifyCodeStep({
    required this.theme,
    required this.codeCtrl,
    required this.phone,
    this.error,
    this.hint,
  });

  final PublicReservarTheme theme;
  final TextEditingController codeCtrl;
  final String phone;
  final String? error;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          hint ?? 'Ingresá el código de 6 dígitos que recibiste por WhatsApp.',
          style: t.textStyle(size: 14, color: t.textSub),
        ),
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Enviado a $phone',
            style: t.textStyle(size: 13, weight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 20),
        TextField(
          controller: codeCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'Código de verificación',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: t.textStyle(size: 13, color: Colors.red.shade700)),
        ],
      ],
    );
  }
}

class _ContactStep extends StatelessWidget {
  const _ContactStep({
    required this.theme,
    required this.formKey,
    required this.nombreCtrl,
    required this.emailCtrl,
    required this.telCtrl,
    this.phoneReadOnly = false,
    this.requireName = true,
  });

  final PublicReservarTheme theme;
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController telCtrl;
  final bool phoneReadOnly;
  final bool requireName;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              if (!requireName) return null;
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
          if (phoneReadOnly)
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Teléfono (verificado)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                telCtrl.text,
                style: t.textStyle(size: 16),
              ),
            )
          else
            AgendaPhoneField(
              controller: telCtrl,
              required: true,
              useKonectaTokens: false,
              helperText:
                  'Obligatorio · te enviaremos un código por WhatsApp para confirmar la reserva',
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.cardBorder),
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.spa_outlined, color: t.primary, size: 22),
              ),
              const SizedBox(width: 14),
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
                  Text('Cualquiera disponible',
                      style: t.textStyle(
                          size: 14, weight: FontWeight.w600)),
                  Text('El primer turno libre con cualquier profesional',
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
    this.hours = const [],
  });

  final PublicReservarTheme theme;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelect;
  final List<BusinessHours> hours;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final today = DateTime.now();
    final dates = List.generate(
      14,
      (i) => DateTime(today.year, today.month, today.day + i),
    ).where((d) => isPublicBookingDayOpen(d, hours)).toList();

    if (dates.isEmpty) {
      return Text(
        'No hay días con horario de atención en las próximas dos semanas.',
        style: t.textStyle(size: 14, color: t.textSub),
      );
    }
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

