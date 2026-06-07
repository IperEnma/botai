import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../providers/agenda/tenant/services_provider.dart';
import '../../register/konecta_tokens.dart';
import '../models/member.dart';
import '../providers/equipo_provider.dart';
import 'member_row.dart';

class MembersTable extends ConsumerWidget {
  const MembersTable({
    super.key,
    required this.state,
    required this.tenantId,
    required this.businessId,
    required this.onMemberTap,
    required this.onStatusChange,
  });

  final EquipoState state;
  final String tenantId;
  final String businessId;
  final void Function(Member) onMemberTap;
  final void Function(String memberId, MemberStatus status) onStatusChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = state.filtered;
    final servicesState = ref.watch(
      servicesProvider((tenantId: tenantId, businessId: businessId)),
    );
    final services = servicesState.items;

    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KTokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (!isMobile) ...[
            _TableHeader(),
            const Divider(height: 1, color: KTokens.border),
          ],
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
                    services: services,
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
          Expanded(flex: 2, child: _HeaderLabel('MIEMBRO')),
          Expanded(flex: 3, child: _HeaderLabel('SERVICIOS')),
          Expanded(flex: 2, child: _HeaderLabel('HORARIO')),
          Expanded(flex: 2, child: _HeaderLabel('ESTADO')),
          Expanded(flex: 1, child: _HeaderLabel('TURNOS')),
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
