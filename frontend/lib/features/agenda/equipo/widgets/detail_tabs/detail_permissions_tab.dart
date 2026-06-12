import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../register/konecta_tokens.dart';
import '../../models/member.dart';
import '../../providers/equipo_provider.dart';

class DetailPermissionsTab extends StatelessWidget {
  const DetailPermissionsTab({
    super.key,
    required this.member,
    required this.notifier,
  });

  final Member member;
  final EquipoNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role cards
          _SectionLabel('ROL'),
          const SizedBox(height: 10),
          _RoleCards(member: member, notifier: notifier),
          const SizedBox(height: 20),

          // Invite access
          _SectionLabel('ACCESO'),
          const SizedBox(height: 10),
          _AccessCard(member: member),
          const SizedBox(height: 20),

          // Session
          if (member.hasAccount && member.inviteAccepted) ...[
            _SectionLabel('SESIÓN ACTIVA'),
            const SizedBox(height: 10),
            _SessionCard(member: member),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        color: KTokens.inkSoft,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─── Role cards ───────────────────────────────────────────────────────────────

class _RoleCards extends StatelessWidget {
  const _RoleCards({required this.member, required this.notifier});

  final Member member;
  final EquipoNotifier notifier;

  @override
  Widget build(BuildContext context) {
    // (type, label, description, comingSoon)
    final types = [
      (
        MemberType.profesionalSoloPerfil,
        'Profesional solo perfil',
        'Aparece en la agenda pero no puede iniciar sesión.',
        false,
      ),
      (
        MemberType.profesionalConCuenta,
        'Profesional con cuenta',
        'Puede iniciar sesión y gestionar su agenda.',
        false,
      ),
      (
        MemberType.recepcion,
        'Recepción con cuenta',
        'Puede gestionar cualquier turno del negocio.',
        false,
      ),
    ];

    return Column(
      children: types.map((t) {
        final (type, name, desc, comingSoon) = t;
        final isActive = member.type == type;
        return Opacity(
          opacity: comingSoon ? 0.45 : 1.0,
          child: GestureDetector(
            onTap: comingSoon
                ? null
                : () => notifier.updateMember(member.copyWith(type: type)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isActive ? KTokens.accentSoft : KTokens.surface,
                border: Border.all(
                  color: isActive ? KTokens.accent : KTokens.border,
                  width: isActive ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    isActive ? KTokens.accent : KTokens.ink,
                              ),
                            ),
                            if (comingSoon) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: KTokens.inkSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'PRÓXIMAMENTE',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                isActive ? KTokens.accent : KTokens.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    const Icon(Icons.check_circle_rounded,
                        color: KTokens.accent, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Access card ──────────────────────────────────────────────────────────────

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    if (!member.hasAccount) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: KTokens.surface,
          border: Border.all(color: KTokens.border),
          borderRadius: BorderRadius.circular(KTokens.rSm),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_off_outlined,
                size: 18, color: KTokens.inkSoft),
            const SizedBox(width: 12),
            Text(
              'Este profesional no tiene cuenta de acceso',
              style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                member.inviteAccepted
                    ? Icons.check_circle_outline_rounded
                    : Icons.mail_outline_rounded,
                size: 18,
                color: member.inviteAccepted
                    ? KTokens.excOpen
                    : KTokens.inkSoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  member.inviteAccepted
                      ? 'Invitación aceptada'
                      : 'Invitación pendiente',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: member.inviteAccepted
                        ? KTokens.excOpen
                        : KTokens.inkMuted,
                  ),
                ),
              ),
              if (member.inviteAcceptedAt != null)
                Text(
                  _formatDate(member.inviteAcceptedAt!),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: KTokens.inkSoft,
                  ),
                ),
            ],
          ),
          if (!member.inviteAccepted) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: KTokens.accent,
                  padding: EdgeInsets.zero,
                  textStyle: GoogleFonts.inter(fontSize: 12),
                ),
                child: const Text('Reenviar invite →'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Session card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.member});
  final Member member;

  String _lastSeenLabel() {
    if (member.lastSeen == null) return 'Nunca';
    final diff = DateTime.now().difference(member.lastSeen!);
    if (diff.inMinutes < 60) return 'HACE ${diff.inMinutes}MIN';
    if (diff.inHours < 24) return 'HACE ${diff.inHours}H';
    return 'HACE ${diff.inDays} DÍAS';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_iphone_rounded,
              size: 20, color: KTokens.inkSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'iPhone 14 · Safari',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: KTokens.ink,
                  ),
                ),
                Text(
                  'MONTEVIDEO · ${_lastSeenLabel()}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: KTokens.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: KTokens.excClosed,
              textStyle: GoogleFonts.inter(fontSize: 12),
              padding: EdgeInsets.zero,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
