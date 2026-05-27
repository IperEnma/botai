import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../controllers/inicio_controller.dart';
import '../models/branch.dart';
import 'branch_avatar.dart';

class BranchesBar extends ConsumerWidget {
  const BranchesBar({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inicioControllerProvider);
    final snapshot = state.snapshot;
    if (snapshot == null) return const SizedBox.shrink();

    final branches = snapshot.branches;
    final selectedId = state.selectedBranchId;
    final isFiltered = selectedId != 'all';
    final selectedBranch = isFiltered
        ? branches.where((b) => b.id == selectedId).firstOrNull
        : null;

    return Container(
      decoration: BoxDecoration(
        color: KTokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Text(
                  'SUCURSALES',
                  style: KTokens.tEyebrow,
                ),
                const SizedBox(width: 10),
                Text(
                  '${branches.where((b) => b.status == BranchStatus.activa).length} ACTIVAS · ${snapshot.turnos.total} TURNOS HOY',
                  style: KTokens.tMonoHint,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Gestionar sucursales →',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: KTokens.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AllBranchesAvatar(
                  totalTurnos: snapshot.turnos.total,
                  isSelected: selectedId == 'all',
                  onTap: () =>
                      ref.read(inicioControllerProvider.notifier).selectBranch('all'),
                ),
                const SizedBox(width: 20),
                for (final branch in branches) ...[
                  BranchAvatar(
                    branch: branch,
                    turnosCount: snapshot.turnos.byBranch[branch.id] ?? 0,
                    isSelected: selectedId == branch.id,
                    onTap: () {
                      if (branch.status == BranchStatus.pausada) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Sucursal en pausa — reactivá desde Sucursales',
                            ),
                          ),
                        );
                        return;
                      }
                      ref
                          .read(inicioControllerProvider.notifier)
                          .selectBranch(branch.id);
                    },
                  ),
                  const SizedBox(width: 20),
                ],
                AddBranchAvatar(onTap: () {}),
              ],
            ),
          ),
          if (isFiltered && selectedBranch != null) ...[
            Divider(height: 1, color: KTokens.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'FILTRANDO POR',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: KTokens.inkSoft,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KTokens.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: KTokens.accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedBranch.color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          selectedBranch.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: KTokens.accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => ref
                              .read(inicioControllerProvider.notifier)
                              .selectBranch('all'),
                          child: Text(
                            '✕',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: KTokens.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'KPIs y turnos abajo limitados',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: KTokens.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
