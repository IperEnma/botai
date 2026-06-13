import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/auth_provider.dart';
import '../../../agenda/register/konecta_tokens.dart';
import '../../../agenda/tenant/widgets/agenda_left_nav.dart' show AgendaNavItem;

const kPlatformNavWidth = 220.0;

/// Sidebar del panel de plataforma (PLATFORM_ADMIN).
///
/// Solo lo ve el dueño de la app (no se muestra a OW/TA/RC/staff). Item
/// "Ver mi tenant" para cambiar al panel de admin de tenant cuando el PA
/// también tiene un tenant propio.
class PlatformLeftNav extends ConsumerWidget {
  const PlatformLeftNav({super.key, this.nombre});

  final String? nombre;

  void _go(BuildContext context, String location) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
    context.go(location);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final initials =
        (nombre?.isNotEmpty == true) ? nombre![0].toUpperCase() : 'P';
    final loc = GoRouterState.of(context).matchedLocation;
    final selectedDashboard = loc == '/admin/platform';
    final selectedTenants = loc == '/admin/platform/tenants';
    final selectedCategorias = loc == '/admin/platform/categorias';

    return Container(
      width: kPlatformNavWidth,
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border(right: BorderSide(color: KTokens.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPad + 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'konecta',
                  style: KTokens.tBrand.copyWith(color: KTokens.accent),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: KTokens.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PLATAFORMA',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      letterSpacing: 0.8,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          AgendaNavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Dashboard',
            selected: selectedDashboard,
            onTap: () => _go(context, '/admin/platform'),
          ),
          AgendaNavItem(
            icon: Icons.business_outlined,
            label: 'Tenants',
            selected: selectedTenants,
            onTap: () => _go(context, '/admin/platform/tenants'),
          ),
          AgendaNavItem(
            icon: Icons.category_outlined,
            label: 'Categorías',
            selected: selectedCategorias,
            onTap: () => _go(context, '/admin/platform/categorias'),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: KTokens.border),
          const SizedBox(height: 8),
          AgendaNavItem(
            icon: Icons.swap_horiz_rounded,
            label: 'Ver mi tenant',
            onTap: () => _go(context, '/agenda/panel?section=agenda'),
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: KTokens.bg,
              borderRadius: BorderRadius.circular(KTokens.rMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: KTokens.accentSoft,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: KTokens.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre?.isNotEmpty == true ? nombre! : 'Plataforma',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: KTokens.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Platform admin',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: KTokens.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: TextButton.icon(
              onPressed: () {
                ref.read(authStateProvider.notifier).signOut();
                _go(context, '/');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Salir'),
            ),
          ),
        ],
      ),
    );
  }
}
