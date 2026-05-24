import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/agenda/tenant/business_staff_provider.dart';
import '../../register/konecta_tokens.dart';
import '../models/member.dart';
import '../providers/equipo_provider.dart';
import 'detail_tabs/detail_permissions_tab.dart';
import 'detail_tabs/detail_profile_tab.dart';
import 'detail_tabs/detail_schedule_tab.dart';
import 'detail_tabs/detail_services_tab.dart';
import 'member_status_badge.dart';

void showMemberDetailPanel(
  BuildContext context,
  Member member,
  EquipoNotifier notifier,
  EquipoKey key,
) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      barrierDismissible: true,
      pageBuilder: (_, _, _) => _MemberDetailPanel(
        member: member,
        notifier: notifier,
        equipoKey: key,
      ),
      transitionsBuilder: (_, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    ),
  );
}

class _MemberDetailPanel extends ConsumerStatefulWidget {
  const _MemberDetailPanel({
    required this.member,
    required this.notifier,
    required this.equipoKey,
  });

  final Member member;
  final EquipoNotifier notifier;
  final EquipoKey equipoKey;

  @override
  ConsumerState<_MemberDetailPanel> createState() => _MemberDetailPanelState();
}

class _MemberDetailPanelState extends ConsumerState<_MemberDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Member _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _joinedLabel() {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    final m = _member.joinedAt;
    return 'DESDE ${months[m.month - 1]} ${m.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Keep member in sync
    ref.listen(equipoProvider(widget.equipoKey), (_, state) {
      final updated = state.members.firstWhere(
        (m) => m.id == _member.id,
        orElse: () => _member,
      );
      if (mounted) setState(() => _member = updated);
    });

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 560,
        child: Material(
          color: Colors.white,
          elevation: 0,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: KTokens.border)),
            ),
            child: Column(
              children: [
                _PanelHeader(
                  member: _member,
                  joinedLabel: _joinedLabel(),
                  onClose: () => Navigator.of(context).pop(),
                ),
                _QuickStats(member: _member),
                _TabBar(controller: _tabController),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      DetailProfileTab(
                          member: _member, notifier: widget.notifier),
                      DetailServicesTab(
                          member: _member,
                          notifier: widget.notifier,
                          tenantId: widget.equipoKey.tenantId,
                          businessId: widget.equipoKey.businessId),
                      DetailScheduleTab(
                          member: _member, notifier: widget.notifier),
                      DetailPermissionsTab(
                          member: _member, notifier: widget.notifier),
                    ],
                  ),
                ),
                _PanelFooter(
                  member: _member,
                  notifier: widget.notifier,
                  equipoKey: widget.equipoKey,
                  onClose: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Panel header ─────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.member,
    required this.joinedLabel,
    required this.onClose,
  });

  final Member member;
  final String joinedLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
      child: Row(
        children: [
          // Avatar 56x56
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: member.color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.initials,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1233),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + type + joined
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: KTokens.ink,
                  ),
                ),
                Text(
                  member.typeLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: KTokens.inkSoft,
                  ),
                ),
                Text(
                  joinedLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: KTokens.inkSoft,
                  ),
                ),
              ],
            ),
          ),

          MemberStatusBadge(status: member.status),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: KTokens.inkMuted,
            onPressed: onClose,
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

// ─── Quick stats ──────────────────────────────────────────────────────────────

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        member.turnosCompletados.toString(),
        'TURNOS COMPLETADOS',
      ),
      (
        member.avgRating > 0
            ? member.avgRating.toStringAsFixed(1)
            : '—',
        'PUNTUACIÓN MEDIA',
      ),
      (
        member.turnosHoy == 0 ? '—' : member.turnosHoy.toString(),
        'TURNOS HOY',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: stats
            .map((s) => Expanded(child: _StatBox(value: s.$1, label: s.$2)))
            .toList(),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontStyle: FontStyle.italic,
              color: KTokens.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: KTokens.inkSoft,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: KTokens.border)),
      ),
      child: TabBar(
        controller: controller,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelColor: KTokens.ink,
        unselectedLabelColor: KTokens.inkMuted,
        indicatorColor: KTokens.accent,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: const [
          Tab(text: 'Perfil'),
          Tab(text: 'Servicios'),
          Tab(text: 'Horarios'),
          Tab(text: 'Permisos'),
        ],
      ),
    );
  }
}

// ─── Panel footer ─────────────────────────────────────────────────────────────

class _PanelFooter extends ConsumerWidget {
  const _PanelFooter({
    required this.member,
    required this.notifier,
    required this.equipoKey,
    required this.onClose,
  });

  final Member member;
  final EquipoNotifier notifier;
  final EquipoKey equipoKey;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffKey = (tenantId: equipoKey.tenantId, businessId: equipoKey.businessId);
    final isSaving = ref.watch(businessStaffProvider(staffKey)).isSaving;

    Future<void> save() async {
      final staffNotifier = ref.read(businessStaffProvider(staffKey).notifier);
      final statusStr = switch (member.status) {
        MemberStatus.activo => 'ACTIVO',
        MemberStatus.pausado => 'PAUSADO',
        MemberStatus.archivado => 'ARCHIVADO',
      };

      // Guardar perfil + status + schedule
      final colorHex =
          '#${(member.color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
      await staffNotifier.updateMember(
        member.id,
        member.name,
        member.title,
        member.avatarUrl,
        member.phone,
        member.email,
        member.bio,
        colorHex,
        statusStr,
        member.customSchedule?.toJson(),
      );

      // Guardar servicios
      final ok = await staffNotifier.updateMemberServices(
          member.id, member.serviceIds);
      if (ok && context.mounted) onClose();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: KTokens.border)),
      ),
      child: Row(
        children: [
          if (member.status != MemberStatus.archivado)
            TextButton(
              onPressed: () {
                notifier.setStatus(member.id, MemberStatus.archivado);
                onClose();
              },
              style: TextButton.styleFrom(
                foregroundColor: KTokens.excClosed,
                textStyle: GoogleFonts.inter(fontSize: 13),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Archivar miembro'),
            ),
          const Spacer(),
          if (member.status == MemberStatus.activo)
            OutlinedButton(
              onPressed: () {
                notifier.setStatus(member.id, MemberStatus.pausado);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: KTokens.ink,
                side: const BorderSide(color: KTokens.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KTokens.rSm),
                ),
                textStyle: GoogleFonts.inter(fontSize: 13),
              ),
              child: const Text('Pausar'),
            ),
          if (member.status == MemberStatus.pausado ||
              member.status == MemberStatus.archivado)
            OutlinedButton(
              onPressed: () {
                notifier.setStatus(member.id, MemberStatus.activo);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: KTokens.accent,
                side: const BorderSide(color: KTokens.accent),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KTokens.rSm),
                ),
                textStyle: GoogleFonts.inter(fontSize: 13),
              ),
              child: const Text('Reactivar'),
            ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isSaving ? null : save,
            style: ElevatedButton.styleFrom(
              backgroundColor: KTokens.ink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              textStyle: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
