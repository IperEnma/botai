import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/agenda/me_profile_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../../agenda/register/konecta_tokens.dart';
import 'widgets/platform_left_nav.dart';

/// Panel de plataforma para el PLATFORM_ADMIN.
///
/// Iteración 1: shell con sidebar y placeholder de las secciones. Las stats,
/// listado de tenants y catálogo global se enchufan en iteraciones siguientes.
class PlatformAdminScreen extends ConsumerWidget {
  const PlatformAdminScreen({super.key, this.section = 'dashboard'});

  /// Subsección activa. La ruta `/admin/platform` mapea a `dashboard`;
  /// `/admin/platform/tenants` a `tenants`; `/admin/platform/categorias` a
  /// `categorias`.
  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(body: AgendaLoadingView());
    }

    final profileAsync = ref.watch(meProfileProvider);
    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFFBFAF7),
        body: AgendaLoadingView(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFFBFAF7),
        body: AgendaErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(meProfileProvider),
        ),
      ),
      data: (profile) {
        if (!profile.platformAdmin) {
          // Quien llegue acá sin rol PA va al panel de tenant. Defensa UX —
          // los endpoints igual rechazarían con 403.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/agenda/panel');
          });
          return const Scaffold(body: AgendaLoadingView());
        }

        final nombre = auth.user?.name;
        final leftNav = PlatformLeftNav(nombre: nombre);
        final isWide = MediaQuery.sizeOf(context).width >= 1024.0;

        Widget content = _placeholderContent();

        if (isWide) {
          return Scaffold(
            backgroundColor: const Color(0xFFFBFAF7),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leftNav,
                Expanded(child: Scaffold(body: content)),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: const Color(0xFFFBFAF7),
          drawer:
              Drawer(width: kPlatformNavWidth, child: leftNav),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: KTokens.ink,
            elevation: 0,
            title: Text(_sectionTitle(),
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          body: content,
        );
      },
    );
  }

  String _sectionTitle() => switch (section) {
        'tenants' => 'Tenants',
        'categorias' => 'Categorías globales',
        _ => 'Plataforma',
      };

  Widget _placeholderContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _eyebrow(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: KTokens.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(_sectionTitle(), style: KTokens.tDisplay),
              const SizedBox(height: 12),
              Text(
                _description(),
                style:
                    GoogleFonts.inter(fontSize: 14, color: KTokens.inkMuted),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(KTokens.rMd),
                  border: Border.all(color: KTokens.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.construction_rounded,
                        size: 22, color: KTokens.inkSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'En construcción',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: KTokens.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'KPIs, tabla de tenants y gestión global llegan en '
                            'la próxima iteración.',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: KTokens.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _eyebrow() => switch (section) {
        'tenants' => 'NEGOCIOS REGISTRADOS',
        'categorias' => 'CATÁLOGO GLOBAL',
        _ => 'PANEL DE PLATAFORMA',
      };

  String _description() => switch (section) {
        'tenants' =>
          'Lista de cuentas con sus negocios, fechas de alta y métricas.',
        'categorias' =>
          'Categorías que ofrecen los negocios — visibles en el buscador público.',
        _ =>
          'Resumen del estado de la plataforma: tenants, negocios y reservas.',
      };
}
