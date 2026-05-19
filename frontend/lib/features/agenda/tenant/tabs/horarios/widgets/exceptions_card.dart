import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../../../../providers/agenda/tenant/horarios_controller_provider.dart';
import '../panels/new_exception_panel.dart';
import 'exception_row.dart';

class ExceptionsCard extends ConsumerWidget {
  const ExceptionsCard({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  ({String tenantId, String businessId}) get _key =>
      (tenantId: tenantId, businessId: businessId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exceptions = ref.watch(
      horariosControllerProvider(_key).select((s) => s.exceptions),
    );
    final notifier = ref.read(horariosControllerProvider(_key).notifier);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Excepciones',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: KTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Días puntuales en los que cambiás el horario regular.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: KTokens.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _AddButton(
                onTap: () => showNewExceptionPanel(
                  context,
                  onSave: notifier.addException,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: KTokens.border),
          const SizedBox(height: 8),
          // Rows or empty state
          if (exceptions.isEmpty)
            _EmptyState()
          else
            ...exceptions.map(
              (e) => ExceptionRow(
                key: ValueKey(e.id),
                exception: e,
                onTap: () => showNewExceptionPanel(
                  context,
                  existing: e,
                  onSave: (updated) {
                    notifier.removeException(e.id);
                    notifier.addException(updated);
                  },
                ),
                onDelete: () => notifier.removeException(e.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: KTokens.accentSoft,
          borderRadius: BorderRadius.circular(KTokens.rPill),
          border: Border.all(
            color: KTokens.accent.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: KTokens.accent),
            const SizedBox(width: 4),
            Text(
              'Agregar excepción',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: KTokens.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(KTokens.rSm),
        border: Border.all(
          color: KTokens.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 28,
            color: KTokens.inkPlaceholder,
          ),
          const SizedBox(height: 8),
          Text(
            'Sin excepciones configuradas',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: KTokens.inkMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Agregá feriados, vacaciones o días con horario especial.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: KTokens.inkSoft,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KTokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}
