import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../controllers/servicios_controller.dart';

class ServiciosToolbar extends StatefulWidget {
  const ServiciosToolbar({
    super.key,
    required this.state,
    required this.notifier,
  });

  final ServiciosState state;
  final ServiciosNotifier notifier;

  @override
  State<ServiciosToolbar> createState() => _ServiciosToolbarState();
}

class _ServiciosToolbarState extends State<ServiciosToolbar> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = widget.notifier;
    final totalActivos = state.countActive;
    final totalTurnos = state.totalBookingsThisMonth;

    return Row(
      children: [
        // Search pill
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: KTokens.surface,
              border: Border.all(color: KTokens.border),
              borderRadius: BorderRadius.circular(KTokens.rSm),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded,
                    size: 16, color: KTokens.inkSoft),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.inter(fontSize: 13, color: KTokens.ink),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'Buscar por nombre o servicio...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: KTokens.inkPlaceholder,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: notifier.setQuery,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Filter tabs
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F0EC),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              _FilterTab(
                label: 'Todos',
                count: state.items.length,
                isActive: state.filter == ServicioFilter.all,
                onTap: () => notifier.setFilter(ServicioFilter.all),
              ),
              _FilterTab(
                label: 'Activos',
                count: state.countActive,
                isActive: state.filter == ServicioFilter.active,
                onTap: () => notifier.setFilter(ServicioFilter.active),
              ),
              _FilterTab(
                label: 'Inactivos',
                count: state.countInactive,
                isActive: state.filter == ServicioFilter.inactive,
                onTap: () => notifier.setFilter(ServicioFilter.inactive),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Counter
        Text(
          '$totalActivos ACTIVOS · $totalTurnos TURNOS ESTE MES',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            letterSpacing: 1.2,
            color: KTokens.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: isActive ? KTokens.ink : KTokens.inkMuted,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: isActive ? KTokens.ink : KTokens.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
