import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/agenda_phone.dart';
import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/booking.dart';
import '../../../models/agenda/availability_slot.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../models/agenda/public_client_profile.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../providers/agenda/public/public_client_session_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import 'public_reservar_identity_step.dart';
import 'public_reservar_layout.dart';
import 'public_reservar_schedule_step.dart';

enum _BookingStep { service, schedule, identity, confirmed }

const int _kBookingTotalSteps = 3;

/// Reserva pÃºblica unificada: /reservar/:slug (mismo look que el sheet del detalle).
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
      case _BookingStep.schedule:
        setState(() {
          _step = _BookingStep.service;
          _selectedDate = null;
          _selectedSlot = null;
        });
      case _BookingStep.identity:
        if (_identityPhase == PublicReservarIdentityPhase.attendee) {
          if (_session != null) {
            setState(() {
              _step = _BookingStep.schedule;
              _identityPhase = PublicReservarIdentityPhase.phone;
            });
          } else {
            setState(() => _identityPhase = PublicReservarIdentityPhase.code);
          }
        } else if (_identityPhase == PublicReservarIdentityPhase.code) {
          setState(() => _identityPhase = PublicReservarIdentityPhase.phone);
        } else {
          setState(() => _step = _BookingStep.schedule);
        }
      case _BookingStep.confirmed:
        break;
    }
  }

  int _stepIndex(_BookingStep step) {
    switch (step) {
      case _BookingStep.service:
        return 1;
      case _BookingStep.schedule:
        return 2;
      case _BookingStep.identity:
        return 3;
      case _BookingStep.confirmed:
        return 3;
    }
  }

  String _stepTitle(_BookingStep step) {
    switch (step) {
      case _BookingStep.service:
        return 'ElegÃ­ un servicio';
      case _BookingStep.schedule:
        return 'ElegÃ­ fecha y horario';
      case _BookingStep.identity:
        return switch (_identityPhase) {
          PublicReservarIdentityPhase.phone => 'VerificÃ¡ tu nÃºmero',
          PublicReservarIdentityPhase.code => 'CÃ³digo de WhatsApp',
          PublicReservarIdentityPhase.attendee => 'Datos del turno',
        };
      case _BookingStep.confirmed:
        return 'ConfirmaciÃ³n';
    }
  }

  String _stepProgressLabel(_BookingStep step) {
    switch (step) {
      case _BookingStep.service:
        return 'Servicio';
      case _BookingStep.schedule:
        return 'Agenda';
      case _BookingStep.identity:
        return 'Datos';
      case _BookingStep.confirmed:
        return 'Listo';
    }
  }

  String? _stepSubtitle(_BookingStep step) {
    switch (step) {
      case _BookingStep.schedule:
        return 'Los dÃ­as marcados tienen turnos libres. PodÃ©s filtrar por profesional.';
      case _BookingStep.identity:
        return switch (_identityPhase) {
          PublicReservarIdentityPhase.phone =>
            'Tu telÃ©fono identifica tu cuenta. DespuÃ©s indicÃ¡s quiÃ©n asiste al turno.',
          PublicReservarIdentityPhase.code =>
            _otpHint ?? 'IngresÃ¡ el cÃ³digo de 6 dÃ­gitos que recibiste por WhatsApp.',
          PublicReservarIdentityPhase.attendee =>
            'PodÃ©s reservar para vos o para otra persona.',
        };
      default:
        return null;
    }
  }

  void _goToIdentity() {
    if (_service == null || _selectedSlot == null || _selectedDate == null) return;
    setState(() {
      _step = _BookingStep.identity;
      _identityPhase = _session != null
          ? PublicReservarIdentityPhase.attendee
          : PublicReservarIdentityPhase.phone;
      _otpError = null;
    });
  }

  void _applyVerifiedClient(PublicClientProfile client) {
    if (!client.needsName && client.nombre.isNotEmpty) {
      _nombreCtrl.text = client.nombre;
    }
    if (client.email != null && client.email!.isNotEmpty) {
      _emailCtrl.text = client.email!;
    }
    _bookingForOther = false;
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
      if (_step == _BookingStep.identity) {
        _identityPhase = PublicReservarIdentityPhase.attendee;
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
    if (svc == null || slot == null) return;
    if (session == null) {
      setState(() => _identityPhase = PublicReservarIdentityPhase.phone);
      return;
    }

    if (!_contactFormKey.currentState!.validate()) return;

    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'IngresÃ¡ el nombre de quien asiste al turno.',
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
        nombreCliente: nombre,
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
            'IngresÃ¡ un telÃ©fono vÃ¡lido con cÃ³digo de paÃ­s.',
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
        _identityPhase = PublicReservarIdentityPhase.code;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar el cÃ³digo: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verifyCode(Business business, PublicReservarTheme theme) async {
    final telefono = normalizeAgendaPhoneDigits(_telCtrl.text);
    if (!isValidAgendaPhone(telefono)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'IngresÃ¡ un telÃ©fono vÃ¡lido con cÃ³digo de paÃ­s.',
            style: theme.textStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _otpError = 'IngresÃ¡ el cÃ³digo de WhatsApp.');
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
      _applyVerifiedClient(result.client);
      if (!mounted) return;
      setState(() {
        _identityPhase = PublicReservarIdentityPhase.attendee;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CÃ³digo invÃ¡lido o vencido: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formattedSelectedDate() {
    final d = _selectedDate;
    if (d == null) return 'â€”';
    const dayNames = ['Lun', 'Mar', 'MiÃ©', 'Jue', 'Vie', 'SÃ¡b', 'Dom'];
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
    return _selectedStaff?.nombre ?? 'â€”';
  }

  Widget? _buildStepFooter(Business business, PublicReservarTheme theme) {
    switch (_step) {
      case _BookingStep.schedule:
        if (_selectedSlot == null) return null;
        return _PrimaryFooterButton(
          theme: theme,
          label: 'Continuar',
          onPressed: _goToIdentity,
        );
      case _BookingStep.identity:
        return switch (_identityPhase) {
          PublicReservarIdentityPhase.phone => _PrimaryFooterButton(
              theme: theme,
              label: 'Enviar cÃ³digo por WhatsApp',
              loading: _submitting,
              onPressed: _submitting ? null : () => _sendOtp(business, theme),
            ),
          PublicReservarIdentityPhase.code => _PrimaryFooterButton(
              theme: theme,
              label: 'Verificar cÃ³digo',
              loading: _submitting,
              onPressed: _submitting ? null : () => _verifyCode(business, theme),
            ),
          PublicReservarIdentityPhase.attendee => _PrimaryFooterButton(
              theme: theme,
              label: 'Confirmar reserva',
              loading: _submitting,
              onPressed: _submitting
                  ? null
                  : () => _submitBookingWithSession(business, theme),
            ),
        };
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
                'Explorar mÃ¡s',
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
                  _confirmedServiceName = null;
                  _confirmedSlotLabel = null;
                  _confirmedDateLabel = null;
                  _confirmedEstado = null;
                  _identityPhase = PublicReservarIdentityPhase.phone;
                  _bookingForOther = false;
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
          progressCurrent: isConfirmed ? _kBookingTotalSteps : _stepIndex(_step),
          progressTotal: _kBookingTotalSteps,
          progressStepLabel: isConfirmed ? 'ConfirmaciÃ³n' : _stepProgressLabel(_step),
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
              ? Text('Este negocio todavÃ­a no publicÃ³ servicios.',
                  style: theme.textStyle(color: theme.textSub))
              : Column(
                  children: [
                    for (final svc in list)
                      _ServiceRow(
                        theme: theme,
                        service: svc,
                        onTap: () => setState(() {
                          _service = svc;
                          _anyStaff = true;
                          _selectedStaff = null;
                          _selectedDate = null;
                          _selectedSlot = null;
                          _step = _BookingStep.schedule;
                        }),
                      ),
                  ],
                ),
        );
      case _BookingStep.schedule:
        return PublicReservarScheduleStep(
          theme: theme,
          slug: widget.slug,
          service: _service!,
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
      case _BookingStep.identity:
        return PublicReservarIdentityStep(
          theme: theme,
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
          serviceName: _service!.nombre,
          dateLabel: _formattedSelectedDate(),
          slotLabel: _selectedSlot?.label ?? 'â€”',
          staffLabel: _staffSummaryLabel(),
          showStaffRow: _usesStaffStep(_service),
          otpError: _otpError,
          otpHint: _otpHint,
          phoneReadOnly: _session != null &&
              _identityPhase == PublicReservarIdentityPhase.attendee,
          requireAttendeeName: true,
        );
      case _BookingStep.confirmed:
        return _BookingConfirmedStep(
          theme: theme,
          businessName: business.nombre,
          serviceName: _confirmedServiceName ?? 'â€”',
          dateLabel: _confirmedDateLabel ?? 'â€”',
          slotLabel: _confirmedSlotLabel ?? 'â€”',
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
          isConfirmed ? 'Â¡Turno confirmado!' : 'Â¡Reserva solicitada!',
          textAlign: TextAlign.center,
          style: t.textStyle(
            size: 24,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isConfirmed
              ? 'Tu turno en $businessName quedÃ³ confirmado. Te esperamos.'
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
          'GuardÃ¡ este nÃºmero de WhatsApp: con el mismo telÃ©fono podÃ©s consultar tus citas por el bot.',
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
