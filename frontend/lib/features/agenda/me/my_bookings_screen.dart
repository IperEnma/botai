import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/booking.dart';
import '../../../providers/agenda/me/bookings_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

const _kPrimary = Color(0xFF6366F1);
const _kAccent  = Color(0xFF8B5CF6);
const _kSurface     = Color(0xFFF8FAFC);
const _kDark        = Color(0xFF0F172A);
const _kMuted       = Color(0xFF64748B);

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  static const _key = (tenantId: null, businessId: null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsProvider(_key));

    return Scaffold(
      backgroundColor: _kSurface,
      body: Column(
        children: [
          _BookingsHero(
            onRefresh: () =>
                ref.read(bookingsProvider(_key).notifier).load(),
          ),
          Expanded(child: _Body(state: state)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/agenda/me/bookings/new'),
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nueva reserva',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}

class _BookingsHero extends StatelessWidget {
  const _BookingsHero({required this.onRefresh});

  final VoidCallback onRefresh;

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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis reservas',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  'Tus turnos confirmados y pendientes',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final BookingsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const key = (tenantId: null, businessId: null);

    if (state.isLoading) return const AgendaLoadingView();
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(bookingsProvider(key).notifier).load(),
      );
    }

    if (state.items.isEmpty) {
      return const AgendaEmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'Sin reservas',
        subtitle: 'Creá tu primera reserva con el botón +',
      );
    }

    final Map<String, List<Booking>> grouped = {};
    for (final b in state.items) {
      final day = _dayKey(b.fechaHoraInicio);
      grouped.putIfAbsent(day, () => []).add(b);
    }
    final days = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i];
        final bookings = grouped[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 10),
              child: Text(
                day.toUpperCase(),
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kMuted,
                    letterSpacing: 1.0),
              ),
            ),
            ...bookings.map((b) => _BookingCard(booking: b)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  static String _dayKey(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookDay = DateTime(dt.year, dt.month, dt.day);
    if (bookDay == today) return 'Hoy';
    if (bookDay == today.add(const Duration(days: 1))) return 'Mañana';
    if (bookDay == today.subtract(const Duration(days: 1))) return 'Ayer';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  Color _statusColor() {
    switch (booking.estado) {
      case BookingEstado.confirmada:
        return const Color(0xFF22C55E);
      case BookingEstado.cancelada:
        return const Color(0xFFEF4444);
      case BookingEstado.completada:
        return Colors.grey;
      case BookingEstado.pendiente:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hora =
        '${booking.fechaHoraInicio.hour.toString().padLeft(2, '0')}:${booking.fechaHoraInicio.minute.toString().padLeft(2, '0')}';
    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: booking.estado.isCancellable
              ? () => _showCancelDialog(context, ref)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.servicioNombre,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kDark),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 13, color: _kMuted),
                          const SizedBox(width: 4),
                          Text(
                            hora,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: _kMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.estado.label,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor),
                      ),
                    ),
                    if (booking.estado.isCancellable) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Mantené para cancelar',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: _kMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CancelBookingDialog(booking: booking),
    );
    if (confirmed != true || !context.mounted) return;
    const key = (tenantId: null, businessId: null);
    try {
      await ref.read(bookingsProvider(key).notifier).cancel(
            businessId: booking.businessId,
            bookingId: booking.id,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al cancelar: $e')));
      }
    }
  }
}

class _CancelBookingDialog extends StatelessWidget {
  const _CancelBookingDialog({required this.booking});

  final Booking booking;

  bool _isOutsideWindow(int hoursCancellationLimit) {
    final diff = booking.fechaHoraInicio.difference(DateTime.now());
    return diff.inHours < hoursCancellationLimit;
  }

  @override
  Widget build(BuildContext context) {
    final outsideWindow = _isOutsideWindow(24);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancelar reserva',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _kDark),
            ),
            const SizedBox(height: 10),
            Text(
              '¿Cancelar la reserva de "${booking.servicioNombre}"?',
              style: GoogleFonts.poppins(fontSize: 13, color: _kMuted),
            ),
            if (outsideWindow) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estás fuera de la ventana de cancelación. '
                        'Se puede aplicar una penalización de créditos.',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Mantener',
                      style: GoogleFonts.poppins(color: _kMuted)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Cancelar reserva',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
