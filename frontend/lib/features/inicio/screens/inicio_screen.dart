import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../controllers/inicio_controller.dart';
import '../widgets/activity_card.dart';
import '../widgets/branches_bar.dart';
import '../widgets/greeting.dart';
import '../widgets/kpis_row.dart';
import '../widgets/quick_actions.dart';
import '../widgets/turnos_card.dart';

class InicioScreen extends ConsumerWidget {
  const InicioScreen({
    super.key,
    required this.businessId,
    required this.tenantId,
    this.businessName,
    this.ownerName,
  });

  final String businessId;
  final String tenantId;
  final String? businessName;
  final String? ownerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inicioControllerProvider);

    if (state.loading && state.snapshot == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (state.error != null && state.snapshot == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error al cargar el dashboard',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: KTokens.inkMuted,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  ref.read(inicioControllerProvider.notifier).refresh(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Greeting(
            ownerName: ownerName,
            businessId: businessId,
          ),
          const SizedBox(height: 24),
          BranchesBar(businessId: businessId),
          const SizedBox(height: 24),
          const KpisRow(),
          const SizedBox(height: 24),
          if (isWide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Expanded(flex: 14, child: TurnosCard()),
                  SizedBox(width: 14),
                  Expanded(flex: 10, child: ActivityCard()),
                ],
              ),
            )
          else ...[
            const TurnosCard(),
            const SizedBox(height: 14),
            const ActivityCard(),
          ],
          const SizedBox(height: 24),
          QuickActions(businessId: businessId),
        ],
      ),
    );
  }
}
