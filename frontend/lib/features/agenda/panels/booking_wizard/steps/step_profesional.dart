import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../../models/agenda/staff_member.dart';
import '../../../../../providers/agenda/tenant/business_staff_provider.dart';
import '../booking_wizard_controller.dart';

class StepProfesional extends ConsumerWidget {
  const StepProfesional({
    super.key,
    required this.controller,
    required this.tenantId,
    required this.businessId,
  });

  final BookingWizardController controller;
  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffState = ref.watch(
      businessStaffProvider((tenantId: tenantId, businessId: businessId)),
    );

    final servicioNombre =
        controller.draft.servicio?.nombre ?? 'este servicio';
    final servicioId = controller.draft.servicio?.id;

    if (!controller.draft.requiresStaffStep) {
      return const SizedBox.shrink();
    }

    // Profesionales asignados a este servicio (o sin restricción explícita)
    final allActive = staffState.members.where((s) => s.activo).toList();
    final filtered = servicioId == null
        ? allActive
        : allActive
            .where((s) =>
                s.serviceIds.isEmpty || s.serviceIds.contains(servicioId))
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Con quién?',
            style: KTokens.tHero,
          ),
          const SizedBox(height: 6),
          Text(
            'Profesionales que ofrecen $servicioNombre en esta sucursal.',
            style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
          ),
          const SizedBox(height: 18),
          Text(
            'PROFESIONAL',
            style: KTokens.tEyebrow.copyWith(fontSize: 10, letterSpacing: 1.4),
          ),
          const SizedBox(height: 10),
          if (staffState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (filtered.isEmpty)
            _EmptyService(servicioNombre: servicioNombre)
          else ...[
            // Staff rows
            ...filtered.asMap().entries.map((entry) {
              final idx = entry.key;
              final member = entry.value;
              final isSelected =
                  !controller.draft.anyProfessional &&
                  controller.draft.profesionalId == member.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ProRow(
                  member: member,
                  idx: idx,
                  isSelected: isSelected,
                  onTap: () =>
                      controller.setProfesional(member.id, any: false),
                ),
              );
            }),
            // "Cualquiera" row
            const SizedBox(height: 4),
            _AnyProfRow(
              isSelected: controller.draft.anyProfessional,
              onTap: () => controller.setProfesional(null, any: true),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProRow extends StatelessWidget {
  const _ProRow({
    required this.member,
    required this.idx,
    required this.isSelected,
    required this.onTap,
  });

  final StaffMember member;
  final int idx;
  final bool isSelected;
  final VoidCallback onTap;

  Color _colorFor(int i) =>
      KTokens.proPalette[i % KTokens.proPalette.length];

  String _initials(String nombre) {
    final parts = nombre.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(idx);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KTokens.rMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isSelected ? KTokens.accentSoft : Colors.white,
          border: Border.all(
            color: isSelected ? KTokens.accent : KTokens.border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(KTokens.rMd),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.25),
              ),
              child: Center(
                child: Text(
                  _initials(member.nombre),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.nombre,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: KTokens.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyService extends StatelessWidget {
  const _EmptyService({required this.servicioNombre});
  final String servicioNombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: KTokens.bg,
        borderRadius: BorderRadius.circular(KTokens.rMd),
        border: Border.all(color: KTokens.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy_outlined,
              size: 32, color: KTokens.inkPlaceholder),
          const SizedBox(height: 10),
          Text(
            'El servicio "$servicioNombre" no cuenta con profesionales disponibles en este momento.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: KTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnyProfRow extends StatelessWidget {
  const _AnyProfRow({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KTokens.rMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isSelected ? KTokens.accentSoft : Colors.white,
          border: Border.all(
            color: isSelected
                ? KTokens.accent
                : KTokens.inkSoft.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(KTokens.rMd),
        ),
        child: Row(
          children: [
            // Placeholder avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: KTokens.inkSoft),
              ),
              child: Center(
                child: Text(
                  '✦',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: KTokens.inkSoft,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cualquiera disponible',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: KTokens.ink,
                  ),
                ),
                Text(
                  'EL PRIMER TURNO LIBRE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: KTokens.inkSoft,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
