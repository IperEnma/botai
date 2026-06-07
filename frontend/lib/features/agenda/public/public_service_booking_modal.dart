import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/agenda_phone.dart';
import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/availability_slot.dart';
import '../../../models/agenda/booking.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/public_client_profile.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/public/public_client_session_provider.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import 'public_reservar_identity_step.dart';
import 'public_reservar_layout.dart';
import 'public_reservar_schedule_step.dart';

enum _ModalStep { service, schedule, identity, confirmed }

/// Abre el flujo de reserva en modal (servicio opcional → calendario → WhatsApp).
Future<void> showPublicServiceBookingModal({
  required BuildContext context,
  required String slug,
  required Business business,
  AgendaService? initialService,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PublicServiceBookingModal(
      slug: slug,
      business: business,
      initialService: initialService,
    ),
  );
}

class PublicServiceBookingModal extends ConsumerStatefulWidget {
  const PublicServiceBookingModal({
    super.key,
    required this.slug,
    required this.business,
    this.initialService,
  });

  final String slug;
  final Business business;
  final AgendaService? initialService;

  @override
  ConsumerState<PublicServiceBookingModal> createState() =>
      _PublicServiceBookingModalState();
}

class _PublicServiceBookingModalState
    extends ConsumerState<PublicServiceBookingModal> {
  late _ModalStep _step;
  AgendaService? _service;
  bool _anyStaff = true;
  StaffMember? _selectedStaff;
  DateTime? _selectedDate;
  AvailabilitySlot? _selectedSlot;
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
  PublicReservarIdentityPhase _identityPhase = PublicReservarIdentityPhase.phone;
  bool _bookingForOther = false;
  String? _confirmedSlotLabel;
  String? _confirmedDateLabel;
  BookingEstado? _confirmedEstado;

  PublicReservarTheme get _theme => PublicReservarTheme.felito();

  bool get _skipsServiceStep => widget.initialService != null;

  AgendaService get _activeService {
    final s = _service;
    if (s == null) {
      throw StateError('No hay servicio seleccionado');
    }
    return s;
  }

  bool get _usesStaff => _service?.requiresStaffSelection ?? false;

  String? get _effectiveStaffId {
    if (!_usesStaff) return null;
    return _anyStaff ? null : _selectedStaff?.id;
  }

  @override
  void initState() {
    super.initState();
    _service = widget.initialService;
    _step = _service != null ? _ModalStep.schedule : _ModalStep.service;
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    if (_sessionRestored) return;
    _sessionRestored = true;
    final stored =
        await ref.read(publicClientSessionStorageProvider).load(widget.slug);
    if (stored == null || stored.businessId != widget.business.id) return;
    if (!mounted) return;
    setState(() {
      _session = stored;
      _telCtrl.text = stored.phone;
      if (stored.nombre != null && !stored.needsName) {
        _nombreCtrl.text = stored.nombre!;
      }
    });
  }

  void _close() => Navigator.of(context).pop();

  void _goBack() {
    switch (_step) {
      case _ModalStep.service:
        _close();
      case _ModalStep.schedule:
        if (_skipsServiceStep) {
          _close();
        } else {
          setState(() {
            _step = _ModalStep.service;
            _selectedDate = null;
            _selectedSlot = null;
          });
        }
      case _ModalStep.identity:
        if (_identityPhase == PublicReservarIdentityPhase.attendee) {
          if (_session != null) {
            setState(() {
              _step = _ModalStep.schedule;
              _identityPhase = PublicReservarIdentityPhase.phone;
            });
          } else {
            setState(() => _identityPhase = PublicReservarIdentityPhase.code);
          }
        } else if (_identityPhase == PublicReservarIdentityPhase.code) {
          setState(() => _identityPhase = PublicReservarIdentityPhase.phone);
        } else {
          setState(() => _step = _ModalStep.schedule);
        }
      case _ModalStep.confirmed:
        _close();
    }
  }

  void _selectService(AgendaService service) {
    setState(() {
      _service = service;
      _anyStaff = true;
      _selectedStaff = null;
      _selectedDate = null;
      _selectedSlot = null;
      _step = _ModalStep.schedule;
    });
  }

  void _goToIdentity() {
    if (_selectedSlot == null || _selectedDate == null) return;
    setState(() {
      _step = _ModalStep.identity;
      _identityPhase = _session != null
          ? PublicReservarIdentityPhase.attendee
          : PublicReservarIdentityPhase.phone;
      _otpError = null;
    });
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
    final isToday =
        d.year == today.year && d.month == today.month && d.day == today.day;
    if (isToday) return 'Hoy';
    return '${dayNames[d.weekday - 1]} ${d.day} ${monthNames[d.month - 1]} ${d.year}';
  }

  String _staffSummaryLabel() {
    if (!_usesStaff) return 'Agenda del negocio';
    if (_anyStaff) return 'Cualquiera disponible';
    return _selectedStaff?.nombre ?? '—';
  }

  List<String> get _progressLabels => _skipsServiceStep
      ? const ['Agenda', 'WhatsApp', 'Confirmar']
      : const ['Servicio', 'Agenda', 'WhatsApp', 'Confirmar'];

  String _stepTitle() {
    switch (_step) {
      case _ModalStep.service:
        return 'Elegí un servicio';
      case _ModalStep.schedule:
        return 'Elegí fecha y horario';
      case _ModalStep.identity:
        return switch (_identityPhase) {
          PublicReservarIdentityPhase.phone => 'Verificá tu WhatsApp',
          PublicReservarIdentityPhase.code => 'Código de WhatsApp',
          PublicReservarIdentityPhase.attendee => 'Confirmá tu reserva',
        };
      case _ModalStep.confirmed:
        return 'Reserva confirmada';
    }
  }

  String? _stepSubtitle() {
    switch (_step) {
      case _ModalStep.service:
        return 'Seleccioná el servicio para ver disponibilidad.';
      case _ModalStep.schedule:
        return 'Filtrá por profesional y elegí un turno disponible.';
      case _ModalStep.identity:
        return switch (_identityPhase) {
          PublicReservarIdentityPhase.phone =>
            'Te enviamos un código por WhatsApp para validar tu número.',
          PublicReservarIdentityPhase.code =>
            _otpHint ?? 'Ingresá el código de 6 dígitos que recibiste.',
          PublicReservarIdentityPhase.attendee =>
            'Revisá los datos y confirmá la reserva.',
        };
      case _ModalStep.confirmed:
        return null;
    }
  }

  int get _progressIndex {
    switch (_step) {
      case _ModalStep.service:
        return 1;
      case _ModalStep.schedule:
        return _skipsServiceStep ? 1 : 2;
      case _ModalStep.identity:
        return _skipsServiceStep ? 2 : 3;
      case _ModalStep.confirmed:
        return _skipsServiceStep ? 3 : 4;
    }
  }

  String get _headerTitle =>
      _service?.nombre ?? (_step == _ModalStep.service ? 'Reservar turno' : widget.business.nombre);

  void _applyVerifiedClient(PublicClientProfile client) {
    if (!client.needsName && client.nombre.isNotEmpty) {
      _nombreCtrl.text = client.nombre;
    }
    if (client.email != null && client.email!.isNotEmpty) {
      _emailCtrl.text = client.email!;
    }
    _bookingForOther = false;
  }

  Future<void> _persistSession(VerifyPublicPhoneResult result) async {
    final telefono = normalizeAgendaPhoneDigits(_telCtrl.text);
    final session = StoredPublicClientSession.fresh(
      token: result.clientSessionToken,
      businessId: widget.business.id,
      phone: telefono,
      needsName: result.client.needsName,
      nombre: result.client.needsName ? null : result.client.nombre,
    );
    await ref.read(publicClientSessionStorageProvider).save(widget.slug, session);
    ref.invalidate(publicClientSessionProvider(widget.slug));
    if (!mounted) return;
    setState(() => _session = session);
  }

  Future<void> _sendOtp() async {
    if (!_contactFormKey.currentState!.validate()) return;
    final telefono = normalizeAgendaPhoneDigits(_telCtrl.text);
    if (!isValidAgendaPhone(telefono)) {
      _snack('Ingresá un teléfono válido con código de país.');
      return;
    }

    setState(() {
      _submitting = true;
      _otpError = null;
    });
    try {
      final api = ref.read(agendaApiServiceProvider);
      final result = await api.sendPublicPhoneVerification(
        businessId: widget.business.id,
        telefono: telefono,
      );
      if (!mounted) return;
      setState(() {
        _otpHint = result.message;
        _identityPhase = PublicReservarIdentityPhase.code;
      });
    } catch (e) {
      _snack('No se pudo enviar el código: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verifyCode() async {
    final telefono = normalizeAgendaPhoneDigits(_telCtrl.text);
    if (!isValidAgendaPhone(telefono)) {
      _snack('Ingresá un teléfono válido con código de país.');
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
        businessId: widget.business.id,
        telefono: telefono,
        code: code,
      );
      await _persistSession(result);
      _applyVerifiedClient(result.client);
      if (!mounted) return;
      setState(() {
        _identityPhase = PublicReservarIdentityPhase.attendee;
      });
    } catch (e) {
      _snack('Código inválido o vencido: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmBooking() async {
    final slot = _selectedSlot;
    final session = _session;
    if (slot == null || session == null) {
      setState(() => _identityPhase = PublicReservarIdentityPhase.phone);
      return;
    }
    if (!_contactFormKey.currentState!.validate()) return;

    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      _snack('Ingresá el nombre de quien asiste al turno.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(agendaApiServiceProvider);
      final booking = await api.publicCreateBooking(
        businessId: widget.business.id,
        serviceId: _activeService.id,
        staffMemberId: _effectiveStaffId,
        fechaHoraInicio: slot.inicio,
        nombreCliente: nombre,
        emailCliente: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
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
        _confirmedSlotLabel = slot.label;
        _confirmedDateLabel = _formattedSelectedDate();
        _confirmedEstado = booking.estado;
        _step = _ModalStep.confirmed;
      });
    } catch (e) {
      _snack('No se pudo confirmar la reserva: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Widget? _buildFooter() {
    final t = _theme;
    switch (_step) {
      case _ModalStep.service:
        return null;
      case _ModalStep.schedule:
        if (_selectedSlot == null) return null;
        return _ModalPrimaryButton(
          theme: t,
          label: 'Continuar',
          onPressed: _goToIdentity,
        );
      case _ModalStep.identity:
        return switch (_identityPhase) {
          PublicReservarIdentityPhase.phone => _ModalPrimaryButton(
              theme: t,
              label: 'Enviar código por WhatsApp',
              loading: _submitting,
              onPressed: _submitting ? null : _sendOtp,
            ),
          PublicReservarIdentityPhase.code => _ModalPrimaryButton(
              theme: t,
              label: 'Verificar código',
              loading: _submitting,
              onPressed: _submitting ? null : _verifyCode,
            ),
          PublicReservarIdentityPhase.attendee => _ModalPrimaryButton(
              theme: t,
              label: 'Confirmar reserva',
              loading: _submitting,
              onPressed: _submitting ? null : _confirmBooking,
            ),
        };
      case _ModalStep.confirmed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModalPrimaryButton(
              theme: t,
              label: 'Listo',
              onPressed: _close,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: t.primary),
              ),
              onPressed: () {
                _close();
                context.go('/reservar/${widget.slug}/mis-reservas');
              },
              child: Text(
                'Ver mis reservas',
                style: t.textStyle(color: t.primary, weight: FontWeight.w600),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxH),
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModalHeader(
                theme: t,
                title: _headerTitle,
                progressLabels: _progressLabels,
                stepIndex: _progressIndex,
                onBack: _step == _ModalStep.confirmed ? null : _goBack,
                onClose: _close,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_step != _ModalStep.confirmed)
                        publicReservarScrollSectionTitle(
                          theme: t,
                          title: _stepTitle(),
                          subtitle: _stepSubtitle(),
                        ),
                      _buildBody(t),
                    ],
                  ),
                ),
              ),
              if (_buildFooter() case final footer?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(PublicReservarTheme t) {
    switch (_step) {
      case _ModalStep.service:
        final servicesAsync =
            ref.watch(publicBusinessServicesBySlugProvider(widget.slug));
        return servicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            'No se pudieron cargar los servicios.',
            style: t.textStyle(color: t.textSub),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                'Este negocio todavía no publicó servicios.',
                style: t.textStyle(color: t.textSub),
              );
            }
            return Column(
              children: [
                for (final svc in list)
                  _ModalServiceRow(
                    theme: t,
                    service: svc,
                    onTap: () => _selectService(svc),
                  ),
              ],
            );
          },
        );
      case _ModalStep.schedule:
        return PublicReservarScheduleStep(
          theme: t,
          slug: widget.slug,
          service: _activeService,
          anyStaff: _anyStaff,
          selectedStaff: _selectedStaff,
          selectedDate: _selectedDate,
          selectedSlot: _selectedSlot,
          onAnyStaffChanged: () => setState(() {
            _anyStaff = true;
            _selectedStaff = null;
            _selectedSlot = null;
          }),
          onStaffChanged: (m) => setState(() {
            _anyStaff = false;
            _selectedStaff = m;
            _selectedSlot = null;
          }),
          onDateChanged: (d) => setState(() {
            _selectedDate = d;
            _selectedSlot = null;
          }),
          onSlotChanged: (s) => setState(() => _selectedSlot = s),
        );
      case _ModalStep.identity:
        return PublicReservarIdentityStep(
          theme: t,
          phase: _identityPhase,
          formKey: _contactFormKey,
          telCtrl: _telCtrl,
          codeCtrl: _codeCtrl,
          attendeeNombreCtrl: _nombreCtrl,
          emailCtrl: _emailCtrl,
          bookingForOther: _bookingForOther,
          onBookingForOtherChanged: (v) => setState(() {
            _bookingForOther = v;
            if (v) {
              _nombreCtrl.clear();
            } else if (_session?.nombre != null && !_session!.needsName) {
              _nombreCtrl.text = _session!.nombre!;
            }
          }),
          serviceName: _activeService.nombre,
          dateLabel: _formattedSelectedDate(),
          slotLabel: _selectedSlot?.label ?? '—',
          staffLabel: _staffSummaryLabel(),
          showStaffRow: _usesStaff,
          otpError: _otpError,
          otpHint: _otpHint,
          phoneReadOnly: _session != null &&
              _identityPhase == PublicReservarIdentityPhase.attendee,
          requireAttendeeName: true,
        );
      case _ModalStep.confirmed:
        return _ModalConfirmedBody(
          theme: t,
          businessName: widget.business.nombre,
          serviceName: _activeService.nombre,
          dateLabel: _confirmedDateLabel ?? '—',
          slotLabel: _confirmedSlotLabel ?? '—',
          estado: _confirmedEstado ?? BookingEstado.pendiente,
        );
    }
  }
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({
    required this.theme,
    required this.title,
    required this.progressLabels,
    required this.stepIndex,
    required this.onClose,
    this.onBack,
  });

  final PublicReservarTheme theme;
  final String title;
  final List<String> progressLabels;
  final int stepIndex;
  final VoidCallback onClose;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack ?? onClose,
                icon: Icon(
                  onBack != null ? Icons.arrow_back : Icons.close,
                  color: t.text,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.textStyle(size: 15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < progressLabels.length; i++) ...[
                          if (i > 0)
                            Container(
                              width: 20,
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              color: i < stepIndex
                                  ? t.primary
                                  : const Color(0xFFD1D5DB),
                            ),
                          _StepDot(
                            theme: t,
                            label: progressLabels[i],
                            active: i + 1 == stepIndex,
                            done: i + 1 < stepIndex,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close, color: t.textSub),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: t.cardBorder),
      ],
    );
  }
}

class _ModalServiceRow extends StatelessWidget {
  const _ModalServiceRow({
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
                    Text(
                      service.nombre,
                      style: t.textStyle(size: 15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${service.duracionMin} min',
                      style: t.textStyle(size: 12, color: t.textSub),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${service.precio.toStringAsFixed(0)}',
                style: t.textStyle(
                  size: 16,
                  weight: FontWeight.w700,
                  color: t.primary,
                ),
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

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.theme,
    required this.label,
    required this.active,
    required this.done,
  });

  final PublicReservarTheme theme;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final color = active || done ? t.primary : const Color(0xFFD1D5DB);
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active || done ? t.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: done && !active
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Text(
                  active ? '●' : '',
                  style: const TextStyle(fontSize: 8, color: Colors.white),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: t.textStyle(
            size: 10,
            weight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? t.primary : t.textSub,
          ),
        ),
      ],
    );
  }
}

class _ModalPrimaryButton extends StatelessWidget {
  const _ModalPrimaryButton({
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

class _ModalConfirmedBody extends StatelessWidget {
  const _ModalConfirmedBody({
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
      children: [
        Icon(Icons.check_circle_rounded, size: 64, color: t.primary),
        const SizedBox(height: 16),
        Text(
          isConfirmed ? '¡Turno confirmado!' : '¡Reserva solicitada!',
          textAlign: TextAlign.center,
          style: t.textStyle(size: 22, weight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          isConfirmed
              ? 'Tu turno en $businessName quedó confirmado.'
              : 'Tu solicitud fue enviada a $businessName.',
          textAlign: TextAlign.center,
          style: t.textStyle(color: t.textSub, size: 14),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.cardFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.cardBorder),
          ),
          child: Column(
            children: [
              _row(t, 'Servicio', serviceName),
              const SizedBox(height: 8),
              _row(t, 'Fecha', dateLabel),
              const SizedBox(height: 8),
              _row(t, 'Horario', slotLabel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(PublicReservarTheme t, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: t.textStyle(color: t.textSub, size: 13)),
        ),
        Expanded(
          child: Text(value, style: t.textStyle(size: 14, weight: FontWeight.w600)),
        ),
      ],
    );
  }
}
