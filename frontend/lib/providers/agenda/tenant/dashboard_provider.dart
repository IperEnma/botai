import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/booking.dart';
import '../agenda_api_provider.dart';

// ── Date range preset ─────────────────────────────────────────────────────────

enum DateRangePreset { thisWeek, thisMonth, last30Days }

extension DateRangePresetX on DateRangePreset {
  String get label => switch (this) {
        DateRangePreset.thisWeek   => 'Esta semana',
        DateRangePreset.thisMonth  => 'Este mes',
        DateRangePreset.last30Days => 'Últimos 30 días',
      };

  ({DateTime from, DateTime to}) get range {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      DateRangePreset.thisWeek =>
        (from: today.subtract(Duration(days: today.weekday - 1)), to: now),
      DateRangePreset.thisMonth =>
        (from: DateTime(now.year, now.month, 1), to: now),
      DateRangePreset.last30Days =>
        (from: today.subtract(const Duration(days: 29)), to: now),
    };
  }
}

// ── Stats model ───────────────────────────────────────────────────────────────

class DashboardStats {
  const DashboardStats({
    this.pending   = 0,
    this.confirmed = 0,
    this.completed = 0,
    this.cancelled = 0,
    required this.from,
    required this.to,
  });

  final int      pending;
  final int      confirmed;
  final int      completed;
  final int      cancelled;
  final DateTime from;
  final DateTime to;

  int get total => pending + confirmed + completed + cancelled;

  double get cancellationRate => total == 0 ? 0 : cancelled / total;
  double get completionRate   => total == 0 ? 0 : completed / total;

  double get dailyAvg {
    final days = max(1, to.difference(from).inDays + 1);
    return total / days;
  }

  factory DashboardStats.fromBookings(
      List<Booking> all, DateTime from, DateTime to) {
    final filtered = all
        .where((b) =>
            !b.fechaHoraInicio.isBefore(from) &&
            !b.fechaHoraInicio.isAfter(to))
        .toList();

    int pending = 0, confirmed = 0, completed = 0, cancelled = 0;
    for (final b in filtered) {
      switch (b.estado) {
        case BookingEstado.pendiente:
          pending++;
        case BookingEstado.confirmada:
          confirmed++;
        case BookingEstado.completada:
          completed++;
        case BookingEstado.cancelada:
          cancelled++;
      }
    }
    return DashboardStats(
      pending:   pending,
      confirmed: confirmed,
      completed: completed,
      cancelled: cancelled,
      from:      from,
      to:        to,
    );
  }
}

// ── Filter key (family parameter) ─────────────────────────────────────────────

class DashboardFilter {
  const DashboardFilter({
    required this.tenantId,
    this.businessId,
    required this.from,
    required this.to,
  });

  final String   tenantId;
  final String?  businessId;
  final DateTime from;
  final DateTime to;

  @override
  bool operator ==(Object other) =>
      other is DashboardFilter &&
      other.tenantId   == tenantId   &&
      other.businessId == businessId &&
      other.from       == from       &&
      other.to         == to;

  @override
  int get hashCode => Object.hash(tenantId, businessId, from, to);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final dashboardStatsProvider = FutureProvider.autoDispose
    .family<DashboardStats, DashboardFilter>((ref, filter) async {
  try {
    final api      = ref.read(agendaApiServiceProvider);
    final bookings = await api.myBookings(
      businessId: filter.businessId,
    );
    return DashboardStats.fromBookings(bookings, filter.from, filter.to);
  } catch (_) {
    // Stats endpoint requires user auth not yet wired — return empty counts.
    return DashboardStats(from: filter.from, to: filter.to);
  }
});
