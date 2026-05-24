import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/staff_member.dart';
import '../../agenda/register/konecta_tokens.dart';
import '../models/service_group.dart';
import '../models/servicio_item.dart';
import 'service_row.dart';

class ServiceGroupCard extends StatelessWidget {
  const ServiceGroupCard({
    super.key,
    required this.group,
    required this.services,
    required this.allStaff,
    required this.staffForService,
    required this.onTapService,
    required this.onAddTo,
    required this.onToggleActive,
    required this.onDuplicateService,
    required this.onDeleteService,
    required this.onMoveService,
    required this.allGroups,
  });

  final ServiceGroup group;
  final List<ServicioItem> services;
  final List<StaffMember> allStaff;
  final List<StaffMember> Function(ServicioItem) staffForService;
  final ValueChanged<ServicioItem> onTapService;
  final ValueChanged<String> onAddTo;
  final ValueChanged<String> onToggleActive;
  final ValueChanged<ServicioItem> onDuplicateService;
  final ValueChanged<String> onDeleteService;
  final void Function(String serviceId, String groupId) onMoveService;
  final List<ServiceGroup> allGroups;

  int get _activeCount => services.where((s) => s.active).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupHeader(
            group: group,
            activeCount: _activeCount,
            totalCount: services.length,
            onAddTo: () => onAddTo(group.id),
          ),
          const Divider(height: 1, color: KTokens.border),
          ...services.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final groupOptions = allGroups
                .where((g) => g.id != group.id)
                .map((g) => (id: g.id, name: g.name))
                .toList();

            return Column(
              children: [
                ServiceRow(
                  service: s,
                  assignedStaff: staffForService(s),
                  onTap: () => onTapService(s),
                  onToggleActive: () => onToggleActive(s.id),
                  onDuplicate: () => onDuplicateService(s),
                  onDelete: () => onDeleteService(s.id),
                  onMoveToGroup: () => _showMoveDialog(context, s, groupOptions),
                  availableGroups: groupOptions,
                ),
                if (i < services.length - 1)
                  const Divider(height: 1, color: KTokens.border),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showMoveDialog(
    BuildContext context,
    ServicioItem service,
    List<({String id, String name})> groups,
  ) {
    showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Mover a otro grupo',
          style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w600, color: KTokens.ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: groups
              .map((g) => ListTile(
                    title: Text(g.name, style: GoogleFonts.inter(fontSize: 14)),
                    onTap: () => Navigator.pop(context, g.id),
                  ))
              .toList(),
        ),
      ),
    ).then((groupId) {
      if (groupId != null) onMoveService(service.id, groupId);
    });
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.activeCount,
    required this.totalCount,
    required this.onAddTo,
  });

  final ServiceGroup group;
  final int activeCount;
  final int totalCount;
  final VoidCallback onAddTo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KTokens.bg,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Row(
        children: [
          Text(
            group.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: KTokens.ink,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$activeCount DE $totalCount ACTIVOS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              letterSpacing: 1.2,
              color: KTokens.inkSoft,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAddTo,
            child: Text(
              '+ Agregar a ${group.name}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: KTokens.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
