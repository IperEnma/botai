import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

/// DEPRECADO: antes resolvía `/agenda/<slug>` → `/agenda/public/business/<id>`.
/// Ahora mantenemos el slug en la URL usando `PublicBusinessDetailBySlugScreen`.
class PublicSlugRedirectScreen extends ConsumerWidget {
  const PublicSlugRedirectScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: ref.read(agendaApiServiceProvider).resolvePublicSlug(slug),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: AgendaLoadingView());
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: AgendaEmptyState(
              icon: Icons.link_off_outlined,
              title: 'Link inválido',
              subtitle: 'Este link público no existe o expiró.',
            ),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/agenda/public/business/${snap.data!}');
          }
        });
        return const Scaffold(body: AgendaLoadingView());
      },
    );
  }
}

