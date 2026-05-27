import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/staff_member.dart';
import '../../agenda/register/konecta_tokens.dart';
import '../models/servicio_item.dart';
import 'service_row.dart';

class ServiciosCard extends StatelessWidget {
  const ServiciosCard({
    super.key,
    required this.services,
    required this.allStaff,
    required this.staffForService,
    required this.onTapService,
    required this.onAdd,
    required this.onToggleActive,
    required this.onDuplicateService,
    required this.onDeleteService,
  });

  final List<ServicioItem> services;
  final List<StaffMember> allStaff;
  final List<StaffMember> Function(ServicioItem) staffForService;
  final ValueChanged<ServicioItem> onTapService;
  final VoidCallback onAdd;
  final ValueChanged<String> onToggleActive;
  final ValueChanged<ServicioItem> onDuplicateService;
  final ValueChanged<String> onDeleteService;

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
          _CardHeader(
            activeCount: _activeCount,
            totalCount: services.length,
            onAdd: onAdd,
          ),
          const Divider(height: 1, color: KTokens.border),
          ...services.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Column(
              children: [
                ServiceRow(
                  service: s,
                  assignedStaff: staffForService(s),
                  onTap: () => onTapService(s),
                  onToggleActive: () => onToggleActive(s.id),
                  onDuplicate: () => onDuplicateService(s),
                  onDelete: () => onDeleteService(s.id),
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
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.activeCount,
    required this.totalCount,
    required this.onAdd,
  });

  final int activeCount;
  final int totalCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KTokens.bg,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Row(
        children: [
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
            onTap: onAdd,
            child: Text(
              '+ Agregar servicio',
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
