import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/agenda/public/public_company_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
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

        final theme = PublicReservarTheme.fromHex(
          colorPrimario: company.colorPrimario,
          colorFondo: company.colorFondo,
          fontFamily: company.fontFamily,
          logoUrl: company.logoUrl,
        );

        return PublicReservarShell(
          theme: theme,
          brandTitle: company.brandName,
          subtitle: company.tagline,
          sectionTitle: 'Elegí tu sucursal',
          onBack: () => context.go('/'),
          footer: publicReservarFooterLink(
            theme: theme,
            onTap: () => context.go('/agenda/me/bookings'),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: company.branches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final branch = company.branches[index];
              return PublicBranchTile(
                nombre: branch.nombre,
                direccion: branch.descripcion,
                theme: theme,
                onTap: () => _goBranch(context, branch.publicSlug),
              );
            },
          ),
        );
      },
    );
  }
}
