import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/booking.dart';
import '../../../models/agenda/subscription.dart';
import '../../../providers/agenda/me/bookings_provider.dart';
import '../../../providers/agenda/me/subscriptions_provider.dart';
import '../../../services/agenda_api_exception.dart';

const _kPrimary = Color(0xFF6366F1);
const _kAccent  = Color(0xFF8B5CF6);
const _kSurface = Color(0xFFF8FAFC);
const _kDark    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);

/// Genera un idempotency key UUID v4 simple.
String _newIdempotencyKey() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return 'ik-$now-${Object().hashCode.abs()}';
}

class CreateBookingScreen extends ConsumerStatefulWidget {
  const CreateBookingScreen({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Idempotency key: mismo para reintentos, nuevo por intento explícito.
  late String _idempotencyKey = _newIdempotencyKey();

  AgendaService? _selectedService;
  Subscription? _selectedSubscription;
  DateTime? _selectedDateTime;
  BookingTipo _tipoReserva = BookingTipo.pagoPorTurno;
  final _notasController = TextEditingController();

  bool _isSubmitting = false;
  String? _submitError;
  bool _canRetry = false;

  final List<AgendaService> _services = const [];

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  static const _bookingsKey = (tenantId: null, businessId: null);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null || _selectedDateTime == null) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
      _canRetry = false;
    });

    try {
      await ref.read(bookingsProvider(_bookingsKey).notifier).create(
            tenantId: widget.tenantId,
            businessId: widget.businessId,
            serviceId: _selectedService!.id,
            fechaHoraInicio: _selectedDateTime!,
            tipoReserva: _tipoReserva,
            subscriptionId: _selectedSubscription?.id,
            notas: _notasController.text.trim().isEmpty
                ? null
                : _notasController.text.trim(),
            idempotencyKey: _idempotencyKey,
          );
      if (mounted) Navigator.pop(context, true);
    } on AgendaApiException catch (e) {
      setState(() {
        _isSubmitting = false;
        _submitError = e.code == 'SLOT_TAKEN'
            ? 'El turno ya no está disponible. Elegí otro horario.'
            : e.message;
        _canRetry = e.status == 0;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _submitError = 'Error inesperado: $e';
        _canRetry = true;
      });
    }
  }

  void _retry() => _submit();

  void _resetForNewAttempt() {
    setState(() {
      _idempotencyKey = _newIdempotencyKey();
      _submitError = null;
      _canRetry = false;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _selectedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _resetForNewAttempt();
    });
  }

  String _formatDateTime(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  @override
  Widget build(BuildContext context) {
    final subsState = ref.watch(subscriptionsProvider);
    final activeSubscriptions =
        subsState.items.where((s) => s.estado.isActive).toList();

    return Scaffold(
      backgroundColor: _kSurface,
      body: Column(
        children: [
          _CreateBookingHero(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  _SectionLabel('Servicio'),
                  const SizedBox(height: 12),
                  _styledDropdown<AgendaService>(
                    label: 'Seleccioná un servicio',
                    value: _selectedService,
                    items: _services
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                '${s.nombre} (${s.duracionMin} min)',
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedService = v;
                      _resetForNewAttempt();
                    }),
                    validator: (v) =>
                        v == null ? 'Seleccioná un servicio' : null,
                    hint: _services.isEmpty
                        ? 'Sin servicios disponibles'
                        : 'Seleccioná un servicio',
                    icon: Icons.spa_outlined,
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel('Fecha y hora'),
                  const SizedBox(height: 12),
                  _DateTimePicker(
                    value: _selectedDateTime,
                    onPick: _pickDateTime,
                    format: _formatDateTime,
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel('Tipo de reserva'),
                  const SizedBox(height: 8),
                  _TypeOption(
                    title: 'Pago por turno',
                    subtitle: 'Pagás en el momento del turno',
                    selected: _tipoReserva == BookingTipo.pagoPorTurno,
                    onTap: () => setState(() {
                      _tipoReserva = BookingTipo.pagoPorTurno;
                      _selectedSubscription = null;
                      _resetForNewAttempt();
                    }),
                  ),
                  if (activeSubscriptions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _TypeOption(
                      title: 'Usar suscripción activa',
                      subtitle: 'Descuenta créditos de tu plan',
                      selected: _tipoReserva == BookingTipo.porSubscripcion,
                      onTap: () => setState(() {
                        _tipoReserva = BookingTipo.porSubscripcion;
                        _resetForNewAttempt();
                      }),
                    ),
                  ],
                  if (_tipoReserva == BookingTipo.porSubscripcion &&
                      activeSubscriptions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _styledDropdown<Subscription>(
                      label: 'Suscripción',
                      value: _selectedSubscription,
                      items: activeSubscriptions
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  '${s.saldoActual} créditos',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedSubscription = v;
                        _resetForNewAttempt();
                      }),
                      validator: (v) =>
                          v == null ? 'Seleccioná una suscripción' : null,
                      hint: 'Seleccioná una suscripción',
                      icon: Icons.card_membership_outlined,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SectionLabel('Notas (opcional)'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notasController,
                    style: GoogleFonts.poppins(fontSize: 14, color: _kDark),
                    maxLines: 3,
                    onChanged: (_) => _resetForNewAttempt(),
                    decoration: _inputDecoration(
                        label: 'Ej: alergia a ciertos productos',
                        icon: Icons.notes_rounded),
                  ),
                  const SizedBox(height: 28),
                  if (_submitError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _submitError!,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_canRetry)
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text('Reintentar',
                            style:
                                GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Confirmar reserva',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
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

  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      hintText: label,
      hintStyle:
          GoogleFonts.poppins(fontSize: 13, color: _kMuted.withValues(alpha: 0.6)),
      prefixIcon: icon != null ? Icon(icon, color: _kMuted, size: 20) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2)),
    );
  }

  Widget _styledDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
    required String hint,
    required IconData icon,
  }) {
    return DropdownButtonFormField<T>(
      decoration: _inputDecoration(label: label, icon: icon),
      style: GoogleFonts.poppins(fontSize: 14, color: _kDark),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      hint: Text(hint,
          style: GoogleFonts.poppins(
              fontSize: 13, color: _kMuted.withValues(alpha: 0.6))),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _CreateBookingHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        24,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                Navigator.of(context).canPop() ? Navigator.pop(context) : null,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva reserva',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  'Elegí servicio, fecha y hora',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
              color: _kPrimary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700, color: _kDark),
        ),
      ],
    );
  }
}

// ── Date/time picker tile ─────────────────────────────────────────────────────

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({
    required this.value,
    required this.onPick,
    required this.format,
  });

  final DateTime? value;
  final VoidCallback onPick;
  final String Function(DateTime) format;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: _kMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null ? format(value!) : 'Seleccioná fecha y hora',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: value != null ? _kDark : _kMuted.withValues(alpha: 0.6)),
              ),
            ),
            Text(
              'Cambiar',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type option ───────────────────────────────────────────────────────────────

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? _kPrimary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kPrimary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _kPrimary : Colors.white,
                border: Border.all(
                    color: selected ? _kPrimary : Colors.grey.shade400,
                    width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? _kPrimary : _kDark),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: _kMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
