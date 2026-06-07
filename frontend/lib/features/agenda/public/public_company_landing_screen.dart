import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/agenda/public/public_company_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import 'public_felito_shell.dart';
import 'public_reservar_layout.dart';

/// Entrada por marca: /reservar?company=felitobarber (mismo shell que el turno).
class PublicCompanyLandingScreen extends ConsumerWidget {
  const PublicCompanyLandingScreen({super.key, required this.companySlug});

  final String companySlug;

  void _goBranch(BuildContext context, String branchSlug) {
    context.go('/reservar/$branchSlug?company=$companySlug');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(publicCompanyProvider(companySlug));

    return companyAsync.when(
      loading: () => const Scaffold(body: AgendaLoadingView()),
      error: (e, _) => Scaffold(
        body: AgendaErrorView(
          message: 'No encontramos esa marca: $e',
          onRetry: () => ref.refresh(publicCompanyProvider(companySlug)),
        ),
      ),
      data: (company) {
        if (company.branches.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              _goBranch(context, company.branches.first.publicSlug);
            }
          });
          return const Scaffold(body: AgendaLoadingView());
        }

        final theme = PublicReservarTheme.felito(logoUrl: company.logoUrl);

        return PublicFelitoBookingShell(
          businessName: company.brandName,
          onBack: () => context.go('/'),
          footer: felitoFooterLink(
            label: 'Ver mis turnos',
            onTap: () => context.go('/agenda/me/bookings'),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (company.tagline != null && company.tagline!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    company.tagline!.trim(),
                    style: FelitoPublicD.t(14, c: FelitoPublicD.muted),
                  ),
                ),
              publicReservarScrollSectionTitle(
                theme: theme,
                title: 'Elegí tu sucursal',
              ),
              ...company.branches.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PublicBranchTile(
                      nombre: b.nombre,
                      direccion: b.descripcion,
                      theme: theme,
                      onTap: () => _goBranch(context, b.publicSlug),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
