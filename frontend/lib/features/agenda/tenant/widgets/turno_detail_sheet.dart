import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../models/agenda/booking.dart';
import '../../../../providers/agenda/agenda_api_provider.dart';
import '../../../../providers/agenda/tenant/agenda_bookings_provider.dart';
import '../../../../providers/agenda/tenant/agenda_month_provider.dart';
import '../../../../providers/agenda/tenant/agenda_week_provider.dart';
import '../../../../services/agenda_api_exception.dart';
import '../../register/konecta_tokens.dart';

Future<void> showTurnoDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String businessId,
  required String tenantId,
  required Booking booking,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _TurnoDetailSheet(
      businessId: businessId,
      tenantId: tenantId,
      booking: booking,
      onConfirmed: () => Navigator.of(ctx).pop(),
    ),
  );
}

class _TurnoDetailSheet extends ConsumerStatefulWidget {
  const _TurnoDetailSheet({
    required this.businessId,
    required this.tenantId,
    required this.booking,
    required this.onConfirmed,
  });

  final String businessId;
  final String tenantId;
  final Booking booking;
  final VoidCallback onConfirmed;

  @override
  ConsumerState<_TurnoDetailSheet> createState() => _TurnoDetailSheetState();
}

class _TurnoDetailSheetState extends ConsumerState<_TurnoDetailSheet> {
  bool _confirming = false;
  late Booking _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      final api = ref.read(agendaApiServiceProvider);
      final updated = await api.confirmTenantBooking(
        businessId: widget.businessId,
        bookingId: _booking.id,
      );
      ref.invalidate(agendaWeekBookingsProvider);
      ref.invalidate(agendaBookingsProvider);
      ref.invalidate(agendaMonthBookingsProvider);
      if (!mounted) return;
      setState(() {
        _booking = updated;
        _confirming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turno confirmado')),
      );
      widget.onConfirmed();
    } on AgendaApiException catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE d MMM · HH:mm', 'es');
    final isPending = _booking.estado == BookingEstado.pendiente;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KTokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _booking.servicioNombre.isNotEmpty
                ? _booking.servicioNombre
                : 'Turno',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontStyle: FontStyle.italic,
              color: KTokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(_booking.fechaHoraInicio),
            style: GoogleFonts.inter(fontSize: 14, color: KTokens.inkMuted),
          ),
          if (_booking.clienteNombre != null &&
              _booking.clienteNombre!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _booking.clienteNombre!,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: KTokens.ink,
              ),
            ),
          ],
          if (_booking.clienteTelefono != null &&
              _booking.clienteTelefono!.isNotEmpty)
            Text(
              _booking.clienteTelefono!,
              style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
            ),
          const SizedBox(height: 16),
          _EstadoChip(estado: _booking.estado),
          if (_booking.notas != null && _booking.notas!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _booking.notas!,
              style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _confirming ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: KTokens.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _confirming
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Confirmar turno',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final BookingEstado estado;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (estado) {
      BookingEstado.pendiente => ('Pendiente de confirmación', const Color(0xFFFFF7ED), const Color(0xFFC2410C)),
      BookingEstado.confirmada => ('Confirmada', const Color(0xFFECFDF5), const Color(0xFF047857)),
      BookingEstado.cancelada => ('Cancelada', const Color(0xFFF3F4F6), KTokens.inkMuted),
      BookingEstado.completada => ('Completada', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
        ),
      ),
    );
  }
}
