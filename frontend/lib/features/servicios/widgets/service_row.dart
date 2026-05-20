import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/staff_member.dart';
import '../../agenda/register/konecta_tokens.dart';
import '../models/service_stats.dart';
import '../models/servicio_item.dart';
import 'pro_avatar_stack.dart';
import 'trend_indicator.dart';

class ServiceRow extends StatefulWidget {
  const ServiceRow({
    super.key,
    required this.service,
    required this.assignedStaff,
    required this.onTap,
    required this.onToggleActive,
    required this.onDuplicate,
    required this.onMoveToGroup,
    required this.onDelete,
    required this.availableGroups,
  });

  final ServicioItem service;
  final List<StaffMember> assignedStaff;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onMoveToGroup;
  final List<({String id, String name})> availableGroups;

  @override
  State<ServiceRow> createState() => _ServiceRowState();
}

class _ServiceRowState extends State<ServiceRow> {
  bool _hovering = false;

  void _handleToggle(BuildContext context) {
    widget.onToggleActive();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    const stats = ServiceStats.zero;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: s.active ? 1.0 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            color: _hovering
                ? const Color(0x04000000)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Toggle
                SizedBox(
                  width: 36,
                  child: _ServicioToggle(
                    value: s.active,
                    onChanged: (_) => _handleToggle(context),
                  ),
                ),

                // Nombre + descripción
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: KTokens.ink,
                        ),
                      ),
                      if (s.description != null &&
                          s.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          s.description!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: KTokens.inkSoft,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Duración
                SizedBox(
                  width: 100,
                  child: s.flexibleDuration
                      ? RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '~ ',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: KTokens.warn,
                                ),
                              ),
                              TextSpan(
                                text: '${s.durationMinutes}m',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: KTokens.warn,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          '${s.durationMinutes}m',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: KTokens.inkSoft,
                          ),
                        ),
                ),

                // Profesionales
                SizedBox(
                  width: 120,
                  child: ProAvatarStack(staff: widget.assignedStaff),
                ),

                // Precio
                SizedBox(
                  width: 120,
                  child: s.priceFrom
                      ? RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'DESDE ',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  color: KTokens.inkSoft,
                                ),
                              ),
                              TextSpan(
                                text: '\$${s.priceUyu}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: KTokens.ink,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          '\$${s.priceUyu}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: KTokens.ink,
                          ),
                        ),
                ),

                // Turnos + trend
                SizedBox(
                  width: 50,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stats.bookingsThisMonth > 0
                            ? '${stats.bookingsThisMonth}'
                            : '—',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: KTokens.inkMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TrendIndicator(trend: stats.trendVsLastMonth),
                    ],
                  ),
                ),

                // Menu
                SizedBox(
                  width: 36,
                  child: _ServiceMenu(
                    service: s,
                    availableGroups: widget.availableGroups,
                    onEdit: widget.onTap,
                    onDuplicate: widget.onDuplicate,
                    onToggle: () => _handleToggle(context),
                    onDelete: widget.onDelete,
                    onMoveToGroup: widget.onMoveToGroup,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Toggle animado ───────────────────────────────────────────────────────────

class _ServicioToggle extends StatelessWidget {
  const _ServicioToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 20,
        decoration: BoxDecoration(
          color: value ? KTokens.accent : const Color(0xFFD8D6D0),
          borderRadius: BorderRadius.circular(KTokens.rPill),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Service menu ─────────────────────────────────────────────────────────────

class _ServiceMenu extends StatelessWidget {
  const _ServiceMenu({
    required this.service,
    required this.availableGroups,
    required this.onEdit,
    required this.onDuplicate,
    required this.onToggle,
    required this.onDelete,
    required this.onMoveToGroup,
  });

  final ServicioItem service;
  final List<({String id, String name})> availableGroups;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onMoveToGroup;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 18, color: KTokens.inkSoft),
      splashRadius: 16,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Text('Editar', style: GoogleFonts.inter(fontSize: 13)),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Text('Duplicar', style: GoogleFonts.inter(fontSize: 13)),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Text(
            service.active ? 'Desactivar' : 'Activar',
            style: GoogleFonts.inter(fontSize: 13),
          ),
        ),
        PopupMenuItem(
          value: 'move',
          child: Text(
            'Mover a otro grupo',
            style: GoogleFonts.inter(fontSize: 13),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Eliminar',
            style: GoogleFonts.inter(fontSize: 13, color: KTokens.excClosed),
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
          case 'duplicate':
            onDuplicate();
          case 'toggle':
            onToggle();
          case 'move':
            onMoveToGroup();
          case 'delete':
            onDelete();
        }
      },
    );
  }
}
