import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../register/konecta_tokens.dart';
import '../data/equipo_mock_data.dart';
import '../models/member.dart';
import 'member_status_badge.dart';

class MemberRow extends StatefulWidget {
  const MemberRow({
    super.key,
    required this.member,
    required this.onTap,
    required this.onStatusChange,
  });

  final Member member;
  final VoidCallback onTap;
  final void Function(MemberStatus) onStatusChange;

  @override
  State<MemberRow> createState() => _MemberRowState();
}

class _MemberRowState extends State<MemberRow> {
  bool _hovering = false;

  double get _opacity => switch (widget.member.status) {
        MemberStatus.pausado => 0.65,
        MemberStatus.archivado => 0.45,
        _ => 1.0,
      };

  String _buildScheduleLabel() {
    final sched = widget.member.customSchedule;
    if (sched == null) return '';

    final days = {
      'LUN': sched.lunes,
      'MAR': sched.martes,
      'MIÉ': sched.miercoles,
      'JUE': sched.jueves,
      'VIE': sched.viernes,
      'SÁB': sched.sabado,
      'DOM': sched.domingo,
    };

    // Check LUN-VIE same schedule
    final weekdays = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE'];
    final weekend = ['SÁB', 'DOM'];

    final openWeekdays = weekdays.where((d) => days[d]!.open).toList();
    final openWeekend = weekend.where((d) => days[d]!.open).toList();

    if (openWeekdays.length == 5) {
      final first = days['LUN']!;
      final allSame = weekdays.every((d) =>
          days[d]!.open &&
          days[d]!.from == first.from &&
          days[d]!.to == first.to);

      if (allSame && openWeekend.isEmpty) {
        return 'LUN-VIE ${first.from?.substring(0, 5) ?? ''}-${first.to?.substring(0, 5) ?? ''}';
      }
      if (allSame && openWeekend.isNotEmpty) {
        final sat = days['SÁB']!;
        if (sat.open) {
          return 'LUN-VIE ${first.from?.substring(0, 5) ?? ''}-${first.to?.substring(0, 5) ?? ''}';
        }
      }
    }

    // Only Saturday
    final allOpen = days.entries.where((e) => e.value.open).toList();
    if (allOpen.length == 1) {
      final entry = allOpen.first;
      return '${entry.key} ${entry.value.from?.substring(0, 5) ?? ''}-${entry.value.to?.substring(0, 5) ?? ''}';
    }

    // Specific days e.g. LUN/MIÉ/VIE
    if (allOpen.isNotEmpty) {
      final labels = allOpen.map((e) => e.key).join('/');
      final first = allOpen.first.value;
      return '$labels ${first.from?.substring(0, 5) ?? ''}-${first.to?.substring(0, 5) ?? ''}';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: _opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            color: _hovering
                ? const Color(0x04000000)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar
                SizedBox(
                  width: 220,
                  child: Row(
                    children: [
                      _Avatar(member: member),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: KTokens.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              member.typeLabel,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: KTokens.inkSoft,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Services
                Expanded(
                  flex: 3,
                  child: _ServiceChips(member: member),
                ),

                // Schedule
                SizedBox(
                  width: 160,
                  child: _ScheduleCell(
                    member: member,
                    scheduleLabel: _buildScheduleLabel(),
                  ),
                ),

                // Status
                SizedBox(
                  width: 110,
                  child: MemberStatusBadge(status: member.status),
                ),

                // Turnos
                SizedBox(
                  width: 80,
                  child: Text(
                    member.turnosHoy == 0 ? '—' : '${member.turnosHoy} hoy',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: member.turnosHoy == 0
                          ? KTokens.inkPlaceholder
                          : KTokens.ink,
                    ),
                  ),
                ),

                // Menu
                _MoreMenu(
                  member: member,
                  onStatusChange: widget.onStatusChange,
                  onEdit: widget.onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: member.color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          member.initials,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1233),
          ),
        ),
      ),
    );
  }
}

// ─── Service chips ────────────────────────────────────────────────────────────

class _ServiceChips extends StatelessWidget {
  const _ServiceChips({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    if (member.serviceIds.isEmpty) {
      return Text(
        'Sin servicios asignados',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: KTokens.inkSoft,
        ),
      );
    }

    const maxVisible = 3;
    final visible = member.serviceIds.take(maxVisible).toList();
    final overflow = member.serviceIds.length - maxVisible;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...visible.map((sid) {
          final info = kMockServices[sid];
          if (info == null) return const SizedBox.shrink();
          return _ServiceChip(label: info.name);
        }),
        if (overflow > 0) _ServiceChip(label: '+$overflow', isOverflow: true),
      ],
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.label, this.isOverflow = false});

  final String label;
  final bool isOverflow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOverflow
            ? const Color(0x14000000)
            : const Color(0x0C000000),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: isOverflow ? KTokens.inkMuted : KTokens.ink,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// ─── Schedule cell ────────────────────────────────────────────────────────────

class _ScheduleCell extends StatelessWidget {
  const _ScheduleCell({required this.member, required this.scheduleLabel});

  final Member member;
  final String scheduleLabel;

  @override
  Widget build(BuildContext context) {
    if (member.status == MemberStatus.archivado) {
      return Text(
        'Archivado',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          color: KTokens.inkPlaceholder,
        ),
      );
    }

    if (!member.isCustomSchedule || scheduleLabel.isEmpty) {
      return Text(
        'Hereda negocio',
        style: GoogleFonts.inter(
          fontSize: 11,
          color: KTokens.inkSoft,
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: KTokens.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            scheduleLabel,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: KTokens.accent,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── More menu ────────────────────────────────────────────────────────────────

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.member,
    required this.onStatusChange,
    required this.onEdit,
  });

  final Member member;
  final void Function(MemberStatus) onStatusChange;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 20, color: KTokens.inkSoft),
      splashRadius: 18,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
          case 'pause':
            onStatusChange(MemberStatus.pausado);
          case 'reactivate':
            onStatusChange(MemberStatus.activo);
          case 'archive':
            onStatusChange(MemberStatus.archivado);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Text('Editar', style: GoogleFonts.inter(fontSize: 13)),
        ),
        if (member.status == MemberStatus.activo)
          PopupMenuItem(
            value: 'pause',
            child: Text('Pausar', style: GoogleFonts.inter(fontSize: 13)),
          ),
        if (member.status == MemberStatus.pausado ||
            member.status == MemberStatus.archivado)
          PopupMenuItem(
            value: 'reactivate',
            child: Text('Reactivar', style: GoogleFonts.inter(fontSize: 13)),
          ),
        if (member.status != MemberStatus.archivado)
          PopupMenuItem(
            value: 'archive',
            child: Text(
              'Archivar',
              style: GoogleFonts.inter(fontSize: 13, color: KTokens.excClosed),
            ),
          ),
      ],
    );
  }
}
