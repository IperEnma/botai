import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../models/agenda/agenda_service.dart';
import '../../../../../providers/agenda/tenant/services_provider.dart';
import '../../../register/konecta_tokens.dart';
import '../../models/member.dart';
import '../../providers/equipo_provider.dart';

class DetailServicesTab extends ConsumerStatefulWidget {
  const DetailServicesTab({
    super.key,
    required this.member,
    required this.notifier,
    required this.tenantId,
    required this.businessId,
  });

  final Member member;
  final EquipoNotifier notifier;
  final String tenantId;
  final String businessId;

  @override
  ConsumerState<DetailServicesTab> createState() => _DetailServicesTabState();
}

class _DetailServicesTabState extends ConsumerState<DetailServicesTab> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.member.serviceIds);
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
    widget.notifier.updateServiceIds(widget.member.id, _selectedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final servicesState = ref.watch(
      servicesProvider(
          (tenantId: widget.tenantId, businessId: widget.businessId)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x0A3B2F63),
              border: Border.all(color: const Color(0x263B2F63)),
              borderRadius: BorderRadius.circular(KTokens.rSm),
            ),
            child: Text(
              'Los servicios asignados son los que el cliente puede elegir al reservar con este profesional.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: KTokens.accent,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (servicesState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (servicesState.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error cargando servicios: ${servicesState.error}',
                style: GoogleFonts.inter(
                    fontSize: 13, color: KTokens.excClosed),
              ),
            )
          else if (servicesState.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No hay servicios creados para este negocio.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: KTokens.inkMuted),
              ),
            )
          else
            _ServicesCard(
              services: servicesState.items.where((s) => s.activo).toList(),
              selectedIds: _selectedIds,
              onToggle: _toggle,
            ),
        ],
      ),
    );
  }
}

class _ServicesCard extends StatelessWidget {
  const _ServicesCard({
    required this.services,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<AgendaService> services;
  final Set<String> selectedIds;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    final assignedCount = services.where((s) => selectedIds.contains(s.id)).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Servicios',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KTokens.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$assignedCount DE ${services.length}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: KTokens.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: KTokens.border),
          ...services.map((s) => _ServiceRow(
                service: s,
                isSelected: selectedIds.contains(s.id),
                onToggle: onToggle,
              )),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.isSelected,
    required this.onToggle,
  });

  final AgendaService service;
  final bool isSelected;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(service.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? KTokens.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isSelected ? KTokens.accent : KTokens.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.nombre,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: KTokens.ink,
                    ),
                  ),
                  Text(
                    '${service.duracionMin} min',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: KTokens.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'UY \$${service.precio.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: KTokens.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
