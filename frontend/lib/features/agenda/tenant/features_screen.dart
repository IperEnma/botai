import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/agenda/tenant/features_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

class FeaturesScreen extends ConsumerWidget {
  const FeaturesScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featuresProvider(tenantId));

    if (state.isLoading) return const AgendaLoadingView();
    if (state.features == null) {
      return AgendaErrorView(
        message: state.error ?? 'No se pudo cargar la configuración.',
        onRetry: () => ref.read(featuresProvider(tenantId).notifier).load(),
      );
    }

    final f = state.features!;

    void toggle({
      bool? agendaEnabled,
      bool? publicSearchEnabled,
      bool? loyaltyEngineEnabled,
      bool? autoNotifications,
    }) {
      ref.read(featuresProvider(tenantId).notifier).update(
            f.copyWith(
              agendaEnabled: agendaEnabled,
              publicSearchEnabled: publicSearchEnabled,
              loyaltyEngineEnabled: loyaltyEngineEnabled,
              autoNotifications: autoNotifications,
            ),
          );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    state.error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ),
          SwitchListTile(
            value: f.agendaEnabled,
            onChanged: (v) => toggle(agendaEnabled: v),
            title: const Text('Módulo Agenda habilitado'),
            subtitle: const Text(
                'Activa o desactiva toda la funcionalidad de agenda para este tenant.'),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: f.publicSearchEnabled,
            onChanged: f.agendaEnabled ? (v) => toggle(publicSearchEnabled: v) : null,
            title: const Text('Búsqueda pública'),
            subtitle: const Text(
                'Permite que usuarios anónimos busquen negocios de este tenant.'),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: f.loyaltyEngineEnabled,
            onChanged: f.agendaEnabled ? (v) => toggle(loyaltyEngineEnabled: v) : null,
            title: const Text('Motor de fidelización'),
            subtitle: const Text(
                'Genera sugerencias automáticas de recompensa según asistencias.'),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: f.autoNotifications,
            onChanged: f.agendaEnabled ? (v) => toggle(autoNotifications: v) : null,
            title: const Text('Notificaciones automáticas'),
            subtitle: const Text(
                'Envía alertas automáticas de vencimiento y confirmaciones de reserva.'),
          ),
        ],
      ),
    );
  }
}
