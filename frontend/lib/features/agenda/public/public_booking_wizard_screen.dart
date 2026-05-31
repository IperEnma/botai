import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/availability_slot.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

enum _WizardStep { service, staff, date, slots, details, done }

/// Wizard full-page para reservar: /reservar/:slug
class PublicBookingWizardScreen extends ConsumerStatefulWidget {
  const PublicBookingWizardScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<PublicBookingWizardScreen> createState() =>
      _PublicBookingWizardScreenState();
}

class _PublicBookingWizardScreenState
    extends ConsumerState<PublicBookingWizardScreen> {
  _WizardStep _step = _WizardStep.service;
  AgendaService? _service;
  StaffMember? _staff;
  bool _anyStaff = false;
  DateTime? _date;
  AvailabilitySlot? _slot;
  Future<List<AvailabilitySlot>>? _slotsFuture;

  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Color _primary(Business b) {
    final hex = b.colorPrimario;
    if (hex == null) return const Color(0xFF6366F1);
    final val = int.tryParse('FF${hex.replaceAll('#', '')}', radix: 16);
    return val != null ? Color(val) : const Color(0xFF6366F1);
  }

  void _back(Business business) {
    if (_step == _WizardStep.service) {
      if (Navigator.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
      return;
    }
    setState(() {
      switch (_step) {
        case _WizardStep.staff:
          _step = _WizardStep.service;
        case _WizardStep.date:
          _step = _WizardStep.staff;
          _date = null;
        case _WizardStep.slots:
          _step = _WizardStep.date;
          _slot = null;
        case _WizardStep.details:
          _step = _WizardStep.slots;
        case _WizardStep.done:
        case _WizardStep.service:
          break;
      }
    });
  }

  void _pickDate(DateTime date, Business business) {
    final staffId = _anyStaff ? null : _staff?.id;
    final key = (
      slug: widget.slug,
      serviceId: _service!.id,
      staffMemberId: staffId,
      date:
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    );
    setState(() {
      _date = date;
      _slot = null;
      _step = _WizardStep.slots;
      _slotsFuture = ref.read(availabilityBySlugProvider(key).future);
    });
  }

  Future<void> _confirm(Business business) async {
    final svc = _service;
    final slot = _slot;
    final nombre = _nombreCtrl.text.trim();
    if (svc == null || slot == null || nombre.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final api = ref.read(agendaApiServiceProvider);
      final client = await api.createClient(
        businessId: business.id,
        nombre: nombre,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        telefono: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
      );
      await api.publicCreateBooking(
        businessId: business.id,
        serviceId: svc.id,
        staffMemberId: _anyStaff ? null : _staff?.id,
        fechaHoraInicio: slot.inicio,
        clientId: client.id,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _step = _WizardStep.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo reservar: $e')),
      );
    }
  }

  String _title(_WizardStep step) {
    switch (step) {
      case _WizardStep.service:
        return 'Elegí un servicio';
      case _WizardStep.staff:
        return 'Elegí profesional';
      case _WizardStep.date:
        return 'Elegí una fecha';
      case _WizardStep.slots:
        return 'Elegí un horario';
      case _WizardStep.details:
        return 'Tus datos';
      case _WizardStep.done:
        return '¡Listo!';
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
          message: 'No se pudo cargar: $e',
          onRetry: () => ref.refresh(publicBusinessBySlugProvider(widget.slug)),
        ),
      ),
      data: (business) {
        final primary = _primary(business);
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            title: Text(business.nombre, style: const TextStyle(fontSize: 16)),
            leading: _step == _WizardStep.done
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => _back(business),
                  ),
          ),
          body: _step == _WizardStep.done
              ? _DoneView(primary: primary, business: business)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      color: primary.withValues(alpha: 0.06),
                      child: Text(
                        _title(_step),
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildStep(business, servicesAsync, primary),
                      ),
                    ),
                    if (_step == _WizardStep.details)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _submitting ? null : () => _confirm(business),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Confirmar reserva'),
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
    AsyncValue<List<AgendaService>> servicesAsync,
    Color primary,
  ) {
    switch (_step) {
      case _WizardStep.service:
        return servicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (services) => Column(
            children: [
              for (final svc in services)
                _OptionTile(
                  title: svc.nombre,
                  subtitle: '${svc.duracionMin} min · \$${svc.precio.toStringAsFixed(0)}',
                  primary: primary,
                  onTap: () => setState(() {
                    _service = svc;
                    _step = _WizardStep.staff;
                  }),
                ),
            ],
          ),
        );
      case _WizardStep.staff:
        final staffAsync = ref.watch(publicStaffBySlugProvider(widget.slug));
        return staffAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (staff) => Column(
            children: [
              _OptionTile(
                title: 'Cualquier profesional disponible',
                subtitle: 'Te asignamos el próximo turno libre',
                primary: primary,
                onTap: () => setState(() {
                  _anyStaff = true;
                  _staff = null;
                  _step = _WizardStep.date;
                }),
              ),
              const SizedBox(height: 8),
              for (final m in staff)
                _OptionTile(
                  title: m.nombre,
                  subtitle: m.rol ?? '',
                  primary: primary,
                  onTap: () => setState(() {
                    _anyStaff = false;
                    _staff = m;
                    _step = _WizardStep.date;
                  }),
                ),
            ],
          ),
        );
      case _WizardStep.date:
        final today = DateTime.now();
        final dates = List.generate(
            14, (i) => DateTime(today.year, today.month, today.day + i));
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dates.map((d) {
            final label =
                '${d.day}/${d.month}';
            return ActionChip(
              label: Text(label),
              onPressed: () => _pickDate(d, business),
              backgroundColor: primary.withValues(alpha: 0.08),
            );
          }).toList(),
        );
      case _WizardStep.slots:
        if (_slotsFuture == null) return const SizedBox.shrink();
        return FutureBuilder<List<AvailabilitySlot>>(
          future: _slotsFuture,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final slots = snap.data ?? [];
            if (slots.isEmpty) {
              return Text(
                'No hay turnos para este día. Elegí otra fecha.',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                return ActionChip(
                  label: Text(slot.label),
                  onPressed: () => setState(() {
                    _slot = slot;
                    _step = _WizardStep.details;
                  }),
                  backgroundColor: primary.withValues(alpha: 0.1),
                );
              }).toList(),
            );
          },
        );
      case _WizardStep.details:
        return Column(
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            if (_service != null && _slot != null && _date != null) ...[
              const SizedBox(height: 20),
              Text(
                'Resumen: ${_service!.nombre} · ${_date!.day}/${_date!.month} · ${_slot!.label}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ],
        );
      case _WizardStep.done:
        return const SizedBox.shrink();
    }
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.primary, required this.business});

  final Color primary;
  final Business business;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 72, color: primary),
            const SizedBox(height: 16),
            Text(
              '¡Turno solicitado!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Te confirmaremos por email o WhatsApp si dejaste contacto.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              style: FilledButton.styleFrom(backgroundColor: primary),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
