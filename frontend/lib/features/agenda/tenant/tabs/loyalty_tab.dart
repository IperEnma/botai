import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/loyalty_suggestion.dart';
import '../../../../providers/agenda/tenant/loyalty_provider.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';

class LoyaltyTab extends ConsumerWidget {
  const LoyaltyTab({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tenantId: tenantId, businessId: businessId);
    final state = ref.watch(loyaltyProvider(key));

    if (state.isLoading) return const AgendaLoadingView();
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(loyaltyProvider(key).notifier).load(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: state.items.isEmpty
          ? const AgendaEmptyState(
              icon: Icons.loyalty_outlined,
              title: 'Sin sugerencias',
              subtitle: 'Las sugerencias de fidelización aparecerán acá cuando el motor las genere.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _SuggestionRow(
                suggestion: state.items[i],
                tenantId: tenantId,
                businessId: businessId,
              ),
            ),
    );
  }
}

class _SuggestionRow extends ConsumerWidget {
  const _SuggestionRow({
    required this.suggestion,
    required this.tenantId,
    required this.businessId,
  });

  final LoyaltySuggestion suggestion;
  final String tenantId;
  final String businessId;

  Color _statusColor() {
    switch (suggestion.estado) {
      case LoyaltySuggestionEstado.pendiente:
        return const Color(0xFFF59E0B);
      case LoyaltySuggestionEstado.aceptada:
        return const Color(0xFF22C55E);
      case LoyaltySuggestionEstado.rechazada:
        return const Color(0xFFEF4444);
      case LoyaltySuggestionEstado.enviada:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tenantId: tenantId, businessId: businessId);
    final isPending =
        suggestion.estado == LoyaltySuggestionEstado.pendiente;

    return ListTile(
      title: Text(suggestion.triggerRule),
      subtitle: Text('Usuario: ${suggestion.userId}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(suggestion.estado.label),
            backgroundColor: _statusColor().withValues(alpha: 0.15),
            side: BorderSide(color: _statusColor()),
            labelStyle: TextStyle(color: _statusColor(), fontSize: 11),
            visualDensity: VisualDensity.compact,
          ),
          if (isPending) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              onSelected: (v) async {
                try {
                  if (v == 'accept') {
                    await ref
                        .read(loyaltyProvider(key).notifier)
                        .patch(suggestion.id, LoyaltySuggestionEstado.aceptada);
                  } else if (v == 'reject') {
                    await ref
                        .read(loyaltyProvider(key).notifier)
                        .patch(suggestion.id, LoyaltySuggestionEstado.rechazada);
                  } else if (v == 'send') {
                    await ref
                        .read(loyaltyProvider(key).notifier)
                        .send(suggestion.id);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'accept', child: Text('Aceptar')),
                PopupMenuItem(value: 'reject', child: Text('Rechazar')),
                PopupMenuItem(value: 'send', child: Text('Enviar ahora')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
