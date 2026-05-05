import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/agenda_service.dart';
import '../../../../providers/agenda/tenant/services_provider.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';
import '../widgets/service_form_dialog.dart';

class ServicesTab extends ConsumerWidget {
  const ServicesTab({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tenantId: tenantId, businessId: businessId);
    final state = ref.watch(servicesProvider(key));

    if (state.isLoading) return const AgendaLoadingView();
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(servicesProvider(key).notifier).load(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'services_fab',
        onPressed: () => _onCreate(context, ref, key),
        child: const Icon(Icons.add),
      ),
      body: state.items.isEmpty
          ? const AgendaEmptyState(
              icon: Icons.design_services_outlined,
              title: 'Sin servicios',
              subtitle: 'Creá el primer servicio con el botón +',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _ServiceRow(
                service: state.items[i],
                tenantId: tenantId,
                businessId: businessId,
              ),
            ),
    );
  }

  Future<void> _onCreate(
    BuildContext context,
    WidgetRef ref,
    ({String tenantId, String businessId}) key,
  ) async {
    final result = await showDialog<ServiceFormResult>(
      context: context,
      builder: (_) => const ServiceFormDialog(),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(servicesProvider(key).notifier).create(
            nombre: result.nombre,
            descripcion: result.descripcion,
            duracionMin: result.duracionMin,
            precio: result.precio,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _ServiceRow extends ConsumerWidget {
  const _ServiceRow({
    required this.service,
    required this.tenantId,
    required this.businessId,
  });

  final AgendaService service;
  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tenantId: tenantId, businessId: businessId);

    return ListTile(
      title: Text(service.nombre),
      subtitle: Text('${service.duracionMin} min · \$${service.precio.toStringAsFixed(2)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!service.activo)
            const Chip(
              label: Text('Inactivo'),
              visualDensity: VisualDensity.compact,
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                final result = await showDialog<ServiceFormResult>(
                  context: context,
                  builder: (_) => ServiceFormDialog(initial: service),
                );
                if (result == null || !context.mounted) return;
                try {
                  await ref.read(servicesProvider(key).notifier).update(
                        serviceId: service.id,
                        nombre: result.nombre,
                        descripcion: result.descripcion,
                        duracionMin: result.duracionMin,
                        precio: result.precio,
                        activo: result.activo,
                      );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              } else if (v == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Eliminar servicio'),
                    content: Text(
                        '¿Eliminar "${service.nombre}"? Se desactivará el servicio.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar')),
                    ],
                  ),
                );
                if (confirm != true || !context.mounted) return;
                try {
                  await ref
                      .read(servicesProvider(key).notifier)
                      .delete(service.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }
}
