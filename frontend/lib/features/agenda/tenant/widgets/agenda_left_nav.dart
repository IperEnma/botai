import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/agenda/me_profile_provider.dart';
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
        (nombre?.isNotEmpty == true) ? nombre![0].toUpperCase() : 'U';
    final loc = GoRouterState.of(context).matchedLocation;
    final section =
        GoRouterState.of(context).uri.queryParameters['section'] ?? '';
    // STAFF puro: solo ve la sección "Agenda" — el resto se gatea backend con
    // 403/404 y mostrarlo solo serviría para frustrar al usuario.
    final me = readMeProfileOrEmpty(ref);
    final staffOnly = me.isStaffOnly;
    // RECEPCIÓN: ve Agenda + Clientes. Sin configuración del negocio, sin
    // servicios, sin equipo, sin administradores, sin bot.
    final receptionOnly = me.isReceptionOnly;

    final selectedInicio = (loc == '/agenda/panel' || loc.startsWith('/agenda/panel')) &&
        !loc.contains('/section/') &&
        !loc.contains('/config') &&
        section.isEmpty;
    final selectedBots = loc.startsWith('/bots');
    final selectedAgenda =
        loc == '/agenda/panel' && section == 'agenda';
    final selectedHorarios = loc.contains('/section/hours');
    final selectedEstilos = loc.contains('/section/styles');
    final selectedServicios = loc.contains('/section/services');
    final selectedEquipo = loc.contains('/section/staff');
    final selectedClientes = loc.contains('/section/clientes');
    final selectedConfig = loc.contains('/config');
    final selectedMisHorarios = loc == '/agenda/panel/mis-horarios';

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
              style: KTokens.tBrand.copyWith(color: KTokens.accent),
            ),
          ),
          const SizedBox(height: 28),
          // Nav items
          AgendaNavItem(
            icon: Icons.calendar_today_outlined,
            label: 'Agenda',
            selected: selectedAgenda ||
                ((staffOnly || receptionOnly) && selectedInicio),
            onTap: () => _go(context, '/agenda/panel?section=agenda'),
          ),
          if (staffOnly)
            AgendaNavItem(
              icon: Icons.schedule_outlined,
              label: 'Mis horarios',
              selected: selectedMisHorarios,
              onTap: () => _go(context, '/agenda/panel/mis-horarios'),
            ),
          if (receptionOnly) ...[
            AgendaNavItem(
              icon: Icons.people_outline,
              label: 'Clientes',
              selected: selectedClientes,
              onTap: () => _go(context, '/agenda/panel/section/clientes'),
            ),
            AgendaNavItem(
              icon: Icons.room_service_outlined,
              label: 'Servicios',
              selected: selectedServicios,
              onTap: () => _go(context, '/agenda/panel/section/services'),
            ),
            AgendaNavItem(
              icon: Icons.people_outline,
              label: 'Equipo',
              selected: selectedEquipo,
              onTap: () => _go(context, '/agenda/panel/section/staff'),
            ),
            AgendaNavItem(
              icon: Icons.schedule_outlined,
              label: 'Horarios',
              selected: selectedHorarios,
              onTap: () => _go(context, '/agenda/panel/section/hours'),
            ),
          ],
          if (!staffOnly && !receptionOnly) ...[
            AgendaNavItem(
              icon: Icons.home_outlined,
              label: 'Inicio',
              selected: selectedInicio,
              onTap: () => _go(context, '/agenda/panel'),
            ),
            AgendaNavItem(
              icon: Icons.smart_toy_outlined,
              label: 'Mis bots',
              selected: selectedBots,
              onTap: () => _go(context, '/bots'),
            ),
            AgendaNavItem(
              icon: Icons.people_outline,
              label: 'Clientes',
              selected: selectedClientes,
              onTap: () => _go(context, '/agenda/panel/section/clientes'),
            ),
            AgendaNavItem(
              icon: Icons.schedule_outlined,
              label: 'Horarios',
              selected: selectedHorarios,
              onTap: () => _go(context, '/agenda/panel/section/hours'),
            ),
            AgendaNavItem(
              icon: Icons.palette_outlined,
              label: 'Estilos',
              selected: selectedEstilos,
              onTap: () => _go(context, '/agenda/panel/section/styles'),
            ),
            AgendaNavItem(
              icon: Icons.room_service_outlined,
              label: 'Servicios',
              selected: selectedServicios,
              onTap: () => _go(context, '/agenda/panel/section/services'),
            ),
            AgendaNavItem(
              icon: Icons.people_outline,
              label: 'Equipo',
              selected: selectedEquipo,
              onTap: () => _go(context, '/agenda/panel/section/staff'),
            ),
            AgendaNavItem(
              icon: Icons.settings_outlined,
              label: 'Configuración',
              selected: selectedConfig,
              onTap: () => _go(context, '/agenda/panel/config'),
            ),
            const SizedBox(height: 8),
            const AgendaNavItem(
              icon: Icons.card_membership_outlined,
              label: 'Planes',
              badge: 'PRONTO',
            ),
            const AgendaNavItem(
              icon: Icons.loyalty_outlined,
              label: 'Fidelizaciones',
              badge: 'PRONTO',
            ),
          ],
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

class AgendaNavItem extends StatelessWidget {
  const AgendaNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  /// Etiqueta opcional al final (p. ej. `PRONTO`).
  final String? badge;

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
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? KTokens.accent : KTokens.inkMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: KTokens.accentSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          letterSpacing: 0.8,
                          color: KTokens.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
