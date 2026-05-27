import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/auth_provider.dart';
import '../../register/konecta_tokens.dart';

const kAgendaNavWidth = 200.0;

class AgendaLeftNav extends ConsumerWidget {
  const AgendaLeftNav({
    super.key,
    this.nombre,
    this.businessName,
    this.tenantId,
    this.businessId,
  });

  final String? nombre;
  final String? businessName;
  final String? tenantId;
  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final initials =
        (nombre?.isNotEmpty == true) ? nombre![0].toUpperCase() : 'U';
    final loc = GoRouterState.of(context).matchedLocation;
    final section =
        GoRouterState.of(context).uri.queryParameters['section'] ?? '';

    final selectedInicio = loc.startsWith('/agenda/businesses/') &&
        !loc.contains('/section/') &&
        !loc.contains('/config') &&
        section.isEmpty;
    final selectedBots = loc.startsWith('/bots');
    final selectedAgenda =
        loc.startsWith('/agenda/businesses/') && section == 'agenda';
    final selectedHorarios = loc.contains('/section/hours');
    final selectedEstilos = loc.contains('/section/styles');
    final selectedServicios = loc.contains('/section/services');
    final selectedPlanes = loc.contains('/section/plans');
    final selectedEquipo = loc.contains('/section/staff');

    return Container(
      width: kAgendaNavWidth,
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border(right: BorderSide(color: KTokens.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPad + 24),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'konecta',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: KTokens.accent,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Nav items
          AgendaNavItem(
            icon: Icons.home_outlined,
            label: 'Inicio',
            selected: selectedInicio,
            onTap: businessId != null
                ? () => context.go('/agenda/businesses/$businessId')
                : null,
          ),
          AgendaNavItem(
            icon: Icons.smart_toy_outlined,
            label: 'Mis bots',
            selected: selectedBots,
            onTap: () => context.go('/bots'),
          ),
          AgendaNavItem(
            icon: Icons.calendar_today_outlined,
            label: 'Agenda',
            selected: selectedAgenda,
            onTap: businessId != null
                ? () =>
                    context.go('/agenda/businesses/$businessId?section=agenda')
                : null,
          ),
          const AgendaNavItem(icon: Icons.people_outline, label: 'Clientes'),
          AgendaNavItem(
            icon: Icons.schedule_outlined,
            label: 'Horarios',
            selected: selectedHorarios,
            onTap: businessId != null
                ? () => context
                    .go('/agenda/businesses/$businessId/section/hours')
                : null,
          ),
          AgendaNavItem(
            icon: Icons.palette_outlined,
            label: 'Estilos',
            selected: selectedEstilos,
            onTap: businessId != null
                ? () => context
                    .go('/agenda/businesses/$businessId/section/styles')
                : null,
          ),
          AgendaNavItem(
            icon: Icons.room_service_outlined,
            label: 'Servicios',
            selected: selectedServicios,
            onTap: businessId != null
                ? () => context
                    .go('/agenda/businesses/$businessId/section/services')
                : null,
          ),
          AgendaNavItem(
            icon: Icons.card_membership_outlined,
            label: 'Planes',
            selected: selectedPlanes,
            onTap: businessId != null
                ? () =>
                    context.go('/agenda/businesses/$businessId/section/plans')
                : null,
          ),
          AgendaNavItem(
            icon: Icons.people_outline,
            label: 'Equipo',
            selected: selectedEquipo,
            onTap: businessId != null
                ? () =>
                    context.go('/agenda/businesses/$businessId/section/staff')
                : null,
          ),
          const AgendaNavItem(
              icon: Icons.loyalty_outlined, label: 'Fidelizaciones'),
          AgendaNavItem(
            icon: Icons.settings_outlined,
            label: 'Configuración',
            onTap: businessId != null
                ? () =>
                    context.push('/agenda/businesses/$businessId/config')
                : null,
          ),
          const Spacer(),
          // User profile card
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
                        nombre?.isNotEmpty == true ? nombre! : 'Usuario',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: KTokens.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (businessName != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          businessName!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: KTokens.inkSoft,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                context.go('/');
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

class AgendaNavItem extends StatelessWidget {
  const AgendaNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(KTokens.rMd);
    return MouseRegion(
      cursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 1, 8, 1),
        decoration: BoxDecoration(borderRadius: borderRadius),
        child: Material(
          color: selected ? KTokens.accentSoft : Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            hoverColor: KTokens.accentSoft.withValues(alpha: 0.55),
            splashColor: KTokens.accentSoft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: selected ? KTokens.accent : KTokens.inkSoft,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? KTokens.accent : KTokens.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
