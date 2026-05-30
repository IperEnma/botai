import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../../models/agenda/agenda_service.dart';
import '../../../../../providers/agenda/tenant/services_provider.dart';
import '../booking_wizard_controller.dart';

class StepServicio extends ConsumerWidget {
  const StepServicio({
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
    final servicesState = ref.watch(
      servicesProvider((tenantId: tenantId, businessId: businessId)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Qué servicio?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontStyle: FontStyle.italic,
              color: KTokens.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Elegí lo que se va a hacer. Define la duración del turno.',
            style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
          ),
          const SizedBox(height: 18),
          Text(
            'SERVICIOS',
            style: KTokens.tEyebrow.copyWith(fontSize: 10, letterSpacing: 1.4),
          ),
          const SizedBox(height: 10),
          if (servicesState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (servicesState.error != null)
            Text(
              'Error: ${servicesState.error}',
              style: GoogleFonts.inter(fontSize: 13, color: KTokens.errorColor),
            )
          else
            _ServicesList(
              services: servicesState.items.where((s) => s.activo).toList(),
              selected: controller.draft.servicio,
              onSelect: controller.setServicio,
            ),
        ],
      ),
    );
  }
}

class _ServicesList extends StatelessWidget {
  const _ServicesList({
    required this.services,
    required this.selected,
    required this.onSelect,
  });

  final List<AgendaService> services;
  final AgendaService? selected;
  final void Function(AgendaService) onSelect;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
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
            const Icon(Icons.design_services_outlined,
                size: 32, color: KTokens.inkPlaceholder),
            const SizedBox(height: 10),
            Text(
              'Sin servicios activos en este momento',
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
    return Column(
      children: services.map((s) {
        final isSelected = selected?.id == s.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _ServiceRow(
            service: s,
            isSelected: isSelected,
            onTap: () => onSelect(s),
          ),
        );
      }).toList(),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  final AgendaService service;
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
            color: isSelected ? KTokens.accent : KTokens.border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(KTokens.rMd),
        ),
        child: Row(
          children: [
            _RadioCircle(selected: isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.nombre,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: KTokens.ink,
                    ),
                  ),
                  if (service.descripcion != null &&
                      service.descripcion!.isNotEmpty)
                    Text(
                      service.descripcion!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: KTokens.inkSoft,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${service.duracionMin} MIN',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: KTokens.inkSoft,
                  ),
                ),
                Text(
                  'UY \$${service.precio.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KTokens.ink,
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

class _RadioCircle extends StatelessWidget {
  const _RadioCircle({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? KTokens.accent : KTokens.border,
          width: 1.5,
        ),
        color: Colors.transparent,
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: KTokens.accent,
                ),
              ),
            )
          : null,
    );
  }
}
