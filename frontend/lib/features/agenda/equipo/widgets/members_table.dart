import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../register/konecta_tokens.dart';
import '../models/member.dart';
import '../providers/equipo_provider.dart';
import 'member_row.dart';

class MembersTable extends StatelessWidget {
  const MembersTable({
    super.key,
    required this.state,
    required this.onMemberTap,
    required this.onStatusChange,
  });

  final EquipoState state;
  final void Function(Member) onMemberTap;
  final void Function(String memberId, MemberStatus status) onStatusChange;

  @override
  Widget build(BuildContext context) {
    final members = state.filtered;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KTokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _TableHeader(),
          const Divider(height: 1, color: KTokens.border),
          if (members.isEmpty)
            _EmptyState(hasFilter: state.filterStatus != null || state.searchQuery.isNotEmpty)
          else
            ...members.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              return Column(
                children: [
                  MemberRow(
                    member: m,
                    onTap: () => onMemberTap(m),
                    onStatusChange: (status) => onStatusChange(m.id, status),
                  ),
                  if (i < members.length - 1)
                    const Divider(
                      height: 1,
                      color: KTokens.border,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: _HeaderLabel('MIEMBRO'),
          ),
          Expanded(
            flex: 3,
            child: _HeaderLabel('SERVICIOS'),
          ),
          SizedBox(
            width: 160,
            child: _HeaderLabel('HORARIO'),
          ),
          SizedBox(
            width: 110,
            child: _HeaderLabel('ESTADO'),
          ),
          SizedBox(
            width: 80,
            child: _HeaderLabel('TURNOS'),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        color: KTokens.inkSoft,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded, size: 40, color: KTokens.inkPlaceholder),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'No hay miembros que coincidan'
                : 'Todavía no hay miembros',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: KTokens.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
