import 'package:flutter/material.dart';

class TurnosKpi {
  final int total;
  final int capacity;
  final double trendPct;
  final Map<String, int> byBranch;

  const TurnosKpi({
    required this.total,
    required this.capacity,
    required this.trendPct,
    required this.byBranch,
  });
}

class RevenueKpi {
  final int expectedUyu;
  final int collectedUyu;
  final double trendPct;

  const RevenueKpi({
    required this.expectedUyu,
    required this.collectedUyu,
    required this.trendPct,
  });

  int get pendingUyu => expectedUyu - collectedUyu;
}

class OccupancyKpi {
  final double averagePct;
  final double trendPct;
  final Map<String, double> byBranch;

  const OccupancyKpi({
    required this.averagePct,
    required this.trendPct,
    required this.byBranch,
  });
}

class BotKpi {
  final int turnosFromBot;
  final int turnosTotal;
  final double trendPct;

  const BotKpi({
    required this.turnosFromBot,
    required this.turnosTotal,
    required this.trendPct,
  });

  int get turnosManual => turnosTotal - turnosFromBot;
  double get botPct =>
      turnosTotal > 0 ? turnosFromBot / turnosTotal * 100 : 0.0;
}

class BotActivity {
  final List<int> last7Days;
  final int msgsThisMonth;
  final int msgsQuota;
  final int conversations;
  final int turnosGenerated;
  final double resolutionRate;

  const BotActivity({
    required this.last7Days,
    required this.msgsThisMonth,
    required this.msgsQuota,
    required this.conversations,
    required this.turnosGenerated,
    required this.resolutionRate,
  });

  double get quotaUsedPct =>
      msgsQuota > 0 ? msgsThisMonth / msgsQuota * 100 : 0.0;
}

enum TurnoStatus { confirmado, pendiente, cancelado }

class TurnoSummary {
  final DateTime time;
  final String clientName;
  final String clientInitials;
  final String serviceLabel;
  final String branchName;
  final String branchId;
  final Color professionalColor;
  final int durationMinutes;
  final TurnoStatus status;

  const TurnoSummary({
    required this.time,
    required this.clientName,
    required this.clientInitials,
    required this.serviceLabel,
    required this.branchName,
    required this.branchId,
    required this.professionalColor,
    required this.durationMinutes,
    required this.status,
  });
}
