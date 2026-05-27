import 'branch.dart';
import 'kpi_models.dart';

class DashboardSnapshot {
  final DateTime date;
  final List<Branch> branches;
  final TurnosKpi turnos;
  final RevenueKpi revenue;
  final OccupancyKpi occupancy;
  final BotKpi bot;
  final List<TurnoSummary> upcomingToday;
  final BotActivity activity;

  const DashboardSnapshot({
    required this.date,
    required this.branches,
    required this.turnos,
    required this.revenue,
    required this.occupancy,
    required this.bot,
    required this.upcomingToday,
    required this.activity,
  });

  DashboardSnapshot filteredBy(String branchId) {
    if (branchId == 'all') return this;

    final filteredTurnos = upcomingToday
        .where((t) => t.branchId == branchId)
        .toList();

    final branchTurnosTotal = turnos.byBranch[branchId] ?? 0;
    final branchTurnosCapacity =
        ((branchTurnosTotal / turnos.total) * turnos.capacity).round();
    final filteredByBranchTurnos = {branchId: branchTurnosTotal};

    final branchOccupancy = occupancy.byBranch[branchId] ?? occupancy.averagePct;
    final filteredByBranchOcc = {branchId: branchOccupancy};

    final ratio = turnos.total > 0 ? branchTurnosTotal / turnos.total : 1.0;
    final filteredExpected = (revenue.expectedUyu * ratio).round();
    final filteredCollected = (revenue.collectedUyu * ratio).round();
    final filteredBotTurnos = (bot.turnosFromBot * ratio).round();
    final filteredBotTotal = (bot.turnosTotal * ratio).round();

    return DashboardSnapshot(
      date: date,
      branches: branches,
      turnos: TurnosKpi(
        total: branchTurnosTotal,
        capacity: branchTurnosCapacity,
        trendPct: turnos.trendPct,
        byBranch: filteredByBranchTurnos,
      ),
      revenue: RevenueKpi(
        expectedUyu: filteredExpected,
        collectedUyu: filteredCollected,
        trendPct: revenue.trendPct,
      ),
      occupancy: OccupancyKpi(
        averagePct: branchOccupancy,
        trendPct: occupancy.trendPct,
        byBranch: filteredByBranchOcc,
      ),
      bot: BotKpi(
        turnosFromBot: filteredBotTurnos,
        turnosTotal: filteredBotTotal,
        trendPct: bot.trendPct,
      ),
      upcomingToday: filteredTurnos,
      activity: activity,
    );
  }
}
