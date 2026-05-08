import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import '../../../../models/agenda/booking.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/agenda/agenda_api_provider.dart';
import '../../../../providers/agenda/tenant/agenda_bookings_provider.dart';
import '../../../../services/agenda_api_exception.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';

/// Sección "Agenda" (turnos/calendario) para el panel privado.
///
/// Nota: hoy usa `myBookings` filtrando por tenant/business. Cuando exista un
/// endpoint admin de calendario (turnos del negocio), este widget debería
/// migrar a ese provider.
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
  DateTime _selectedDay = DateTime.now();

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _copyPublicLink() async {
    final api = ref.read(agendaApiServiceProvider);
    final result = await api.mePublicLink();
    final url = result['url'];
    if (!mounted) return;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar el vínculo público')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vínculo copiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBusinessSelector = widget.businesses.length > 1;
    final businessId = widget.businessId;
    if (businessId == null || businessId.isEmpty) {
      return const AgendaEmptyState(
        icon: Icons.store_mall_directory_outlined,
        title: 'Seleccioná una ubicación',
        subtitle: 'Elegí la ubicación para ver el calendario del negocio.',
      );
    }

    final async = ref.watch(agendaBookingsProvider((businessId: businessId, day: _selectedDay)));

    if (async.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (async.hasError) {
      final err = async.error;
      final is401 = err is AgendaApiException && err.status == 401;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AGENDA (CALENDARIO)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            if (is401)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sesión expirada',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Para ver el calendario privado necesitás iniciar sesión otra vez.',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => ref.invalidate(
                              agendaBookingsProvider((businessId: businessId, day: _selectedDay)),
                            ),
                            child: const Text('Reintentar'),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: () async {
                              await ref.read(authStateProvider.notifier).signOut();
                              if (context.mounted) context.go('/login');
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('Iniciar sesión'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              AgendaErrorView(
                message: err?.toString() ?? 'Error al cargar agenda',
                onRetry: () => ref.invalidate(
                  agendaBookingsProvider((businessId: businessId, day: _selectedDay)),
                ),
              ),
          ],
        ),
      );
    }

    final items = [...(async.value ?? const <Booking>[])]
      ..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));

    final selected = _dayOnly(_selectedDay);
    final todays = items.where((b) {
      final d = _dayOnly(b.fechaHoraInicio);
      return d == selected;
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBusinessSelector) ...[
          Text(
            'UBICACIÓN',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          _BusinessSelector(
            businesses: widget.businesses,
            selectedBusinessId: widget.businessId,
            onSelected: (id) => widget.onBusinessSelected?.call(id),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                'AGENDA (CALENDARIO)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.black54,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _copyPublicLink,
              icon: const Icon(Icons.link),
              label: const Text('Copiar vínculo'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: CalendarDatePicker(
            initialDate: _selectedDay,
            firstDate: DateTime(2024),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (d) => setState(() => _selectedDay = d),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Turnos del día',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const AgendaEmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'Sin turnos todavía',
            subtitle: 'Cuando tus clientes reserven, los vas a ver acá.',
          )
        else if (todays.isEmpty)
          const AgendaEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'Sin turnos para este día',
            subtitle: 'Probá con otra fecha en el calendario.',
          )
        else
          ...todays.map((b) => _BookingTile(b: b)),
      ],
    );
  }
}

class _BusinessSelector extends StatelessWidget {
  const _BusinessSelector({
    required this.businesses,
    required this.selectedBusinessId,
    required this.onSelected,
  });

  final List<dynamic> businesses;
  final String? selectedBusinessId;
  final void Function(String businessId) onSelected;

  @override
  Widget build(BuildContext context) {
    // Businesses are `Business` models, but we keep this widget decoupled from
    // the tenant screen giant file by accessing minimal fields dynamically.
    // Expected: `id` + `nombre`.
    String? currentId = selectedBusinessId;
    if (currentId == null && businesses.isNotEmpty) {
      final first = businesses.first;
      currentId = (first as dynamic).id as String?;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: currentId,
            items: [
              for (final b in businesses)
                DropdownMenuItem<String>(
                  value: (b as dynamic).id as String,
                  child: Text(
                    ((b as dynamic).nombre as String?) ?? 'Ubicación',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              onSelected(v);
            },
          ),
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.b});
  final Booking b;

  static String _fmt2(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final d = b.fechaHoraInicio;
    final when = '${_fmt2(d.day)}/${_fmt2(d.month)} ${_fmt2(d.hour)}:${_fmt2(d.minute)}';
    final cliente = b.clienteNombre?.trim();
    final contacto = [
      if (b.clienteEmail != null && b.clienteEmail!.trim().isNotEmpty) b.clienteEmail!.trim(),
      if (b.clienteTelefono != null && b.clienteTelefono!.trim().isNotEmpty) b.clienteTelefono!.trim(),
    ].join(' · ');
    final subtitle = [
      if (b.servicioNombre.isNotEmpty) b.servicioNombre,
      if (cliente != null && cliente.isNotEmpty) cliente,
      if (contacto.isNotEmpty) contacto,
      'Estado: ${b.estado.name}',
    ].join(' · ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: const Icon(Icons.event_available_outlined),
        title: Text(when, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

