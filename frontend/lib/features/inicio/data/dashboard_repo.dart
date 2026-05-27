import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../models/dashboard_snapshot.dart';
import '../models/kpi_models.dart';

class DashboardRepo {
  DashboardSnapshot getMockSnapshot() {
    final now = DateTime.now();

    final branches = [
      Branch(
        id: 'poc',
        name: 'Pocitos',
        initials: 'PO',
        address: 'Av. Brasil 2891, Pocitos',
        color: const Color(0xFFA78BFA),
        status: BranchStatus.activa,
        createdAt: DateTime(2023, 3, 10),
      ),
      Branch(
        id: 'cen',
        name: 'Centro',
        initials: 'CE',
        address: 'Av. 18 de Julio 1050, Centro',
        color: const Color(0xFF34D399),
        status: BranchStatus.activa,
        createdAt: DateTime(2023, 6, 1),
      ),
      Branch(
        id: 'car',
        name: 'Carrasco',
        initials: 'CA',
        address: 'Av. Bolivia 1280, Carrasco',
        color: const Color(0xFFFB923C),
        status: BranchStatus.pausada,
        createdAt: DateTime(2024, 1, 15),
      ),
    ];

    final past = [
      TurnoSummary(
        time: now.subtract(const Duration(hours: 3, minutes: 30)),
        clientName: 'Valentina Rodríguez',
        clientInitials: 'VR',
        serviceLabel: 'CORTE + PEINADO',
        branchName: 'Pocitos',
        branchId: 'poc',
        professionalColor: const Color(0xFFA78BFA),
        durationMinutes: 45,
        status: TurnoStatus.confirmado,
      ),
      TurnoSummary(
        time: now.subtract(const Duration(hours: 2)),
        clientName: 'Martina Sosa',
        clientInitials: 'MS',
        serviceLabel: 'COLORACIÓN',
        branchName: 'Centro',
        branchId: 'cen',
        professionalColor: const Color(0xFF34D399),
        durationMinutes: 90,
        status: TurnoStatus.confirmado,
      ),
      TurnoSummary(
        time: now.subtract(const Duration(minutes: 40)),
        clientName: 'Camila Ferreira',
        clientInitials: 'CF',
        serviceLabel: 'MECHAS',
        branchName: 'Pocitos',
        branchId: 'poc',
        professionalColor: const Color(0xFFA78BFA),
        durationMinutes: 120,
        status: TurnoStatus.pendiente,
      ),
    ];

    final future = [
      TurnoSummary(
        time: now.add(const Duration(minutes: 25)),
        clientName: 'Ana García',
        clientInitials: 'AG',
        serviceLabel: 'CORTE',
        branchName: 'Pocitos',
        branchId: 'poc',
        professionalColor: const Color(0xFF60A5FA),
        durationMinutes: 30,
        status: TurnoStatus.confirmado,
      ),
      TurnoSummary(
        time: now.add(const Duration(hours: 1)),
        clientName: 'Lucas Pérez',
        clientInitials: 'LP',
        serviceLabel: 'AFEITADO + CORTE',
        branchName: 'Centro',
        branchId: 'cen',
        professionalColor: const Color(0xFF34D399),
        durationMinutes: 50,
        status: TurnoStatus.confirmado,
      ),
      TurnoSummary(
        time: now.add(const Duration(hours: 1, minutes: 45)),
        clientName: 'Sofía Núñez',
        clientInitials: 'SN',
        serviceLabel: 'TRATAMIENTO CAPILAR',
        branchName: 'Pocitos',
        branchId: 'poc',
        professionalColor: const Color(0xFFA78BFA),
        durationMinutes: 60,
        status: TurnoStatus.pendiente,
      ),
      TurnoSummary(
        time: now.add(const Duration(hours: 2, minutes: 30)),
        clientName: 'Emilia Suárez',
        clientInitials: 'ES',
        serviceLabel: 'COLORACIÓN + CORTE',
        branchName: 'Centro',
        branchId: 'cen',
        professionalColor: const Color(0xFF34D399),
        durationMinutes: 110,
        status: TurnoStatus.confirmado,
      ),
      TurnoSummary(
        time: now.add(const Duration(hours: 4)),
        clientName: 'Diego Martínez',
        clientInitials: 'DM',
        serviceLabel: 'CORTE',
        branchName: 'Pocitos',
        branchId: 'poc',
        professionalColor: const Color(0xFFF472B6),
        durationMinutes: 30,
        status: TurnoStatus.confirmado,
      ),
    ];

    final allTurnos = [...past, ...future];
    allTurnos.sort((a, b) => a.time.compareTo(b.time));

    return DashboardSnapshot(
      date: now,
      branches: branches,
      turnos: const TurnosKpi(
        total: 24,
        capacity: 35,
        trendPct: 12.0,
        byBranch: {'poc': 12, 'cen': 8, 'car': 4},
      ),
      revenue: const RevenueKpi(
        expectedUyu: 9840,
        collectedUyu: 7560,
        trendPct: -1.0,
      ),
      occupancy: const OccupancyKpi(
        averagePct: 87.0,
        trendPct: -3.0,
        byBranch: {'poc': 91.0, 'cen': 85.0, 'car': 75.0},
      ),
      bot: const BotKpi(
        turnosFromBot: 14,
        turnosTotal: 62,
        trendPct: 12.0,
      ),
      upcomingToday: allTurnos,
      activity: const BotActivity(
        last7Days: [32, 48, 30, 65, 52, 78, 90],
        msgsThisMonth: 248,
        msgsQuota: 1000,
        conversations: 87,
        turnosGenerated: 14,
        resolutionRate: 82.0,
      ),
    );
  }
}
