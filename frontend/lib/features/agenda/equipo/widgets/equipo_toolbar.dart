import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../register/konecta_tokens.dart';
import '../models/member.dart';
import '../providers/equipo_provider.dart';

class EquipoToolbar extends StatelessWidget {
  const EquipoToolbar({
    super.key,
    required this.state,
    required this.onSearch,
    required this.onFilter,
  });

  final EquipoState state;
  final ValueChanged<String> onSearch;
  final ValueChanged<MemberStatus?> onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: _SearchPill(onSearch: onSearch),
        ),
        const SizedBox(width: 20),
        _FilterTabs(state: state, onFilter: onFilter),
        const Spacer(),
        _CounterLabel(state: state),
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: KTokens.surface,
        borderRadius: BorderRadius.circular(KTokens.rSm),
        border: Border.all(color: KTokens.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, size: 16, color: KTokens.inkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onSearch,
              style: GoogleFonts.inter(fontSize: 13, color: KTokens.ink),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o servicio...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: KTokens.inkPlaceholder),
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.state, required this.onFilter});

  final EquipoState state;
  final ValueChanged<MemberStatus?> onFilter;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (null, 'Todos', state.members.length),
      (MemberStatus.activo, 'Activos', state.countActivos),
      (MemberStatus.pausado, 'Pausados', state.countPausados),
      (MemberStatus.archivado, 'Archivados', state.countArchivados),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0EC),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: tabs.map((tab) {
          final (status, label, count) = tab;
          final isActive = state.filterStatus == status;
          return _FilterTab(
            label: label,
            count: count,
            isActive: isActive,
            onTap: () => onFilter(status),
          );
        }).toList(),
      ),
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
            const SizedBox(width: 5),
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

class _CounterLabel extends StatelessWidget {
  const _CounterLabel({required this.state});

  final EquipoState state;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${state.countActivos} ACTIVOS · ${state.totalTurnosHoy} TURNOS HOY',
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        color: KTokens.inkSoft,
      ),
    );
  }
}
