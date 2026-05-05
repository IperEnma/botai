import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/plan.dart';
import '../../../../providers/agenda/tenant/plans_provider.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';
import '../../theme/agenda_tokens.dart';
import '../widgets/plan_form_dialog.dart';

class PlansTab extends ConsumerWidget {
  const PlansTab({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tenantId: tenantId, businessId: businessId);
    final state = ref.watch(plansProvider(key));

    if (state.isLoading) return const AgendaLoadingView();
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(plansProvider(key).notifier).load(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'plans_fab',
        onPressed: () => _onCreate(context, ref, key),
        child: const Icon(Icons.add),
      ),
      body: state.items.isEmpty
          ? const AgendaEmptyState(
              icon: Icons.card_membership_outlined,
              title: 'Sin planes',
              subtitle: 'Creá el primer plan con el botón +',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _PlanRow(
                plan: state.items[i],
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
    final result = await showDialog<PlanFormResult>(
      context: context,
      builder: (_) => const PlanFormDialog(),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(plansProvider(key).notifier).create(
            nombrePlan: result.nombrePlan,
            tipo: result.tipo,
            tier: result.tier,
            totalCreditos: result.totalCreditos,
            validezDias: result.validezDias,
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

class _PlanRow extends ConsumerWidget {
  const _PlanRow({
    required this.plan,
    required this.tenantId,
    required this.businessId,
  });

  final Plan plan;
  final String tenantId;
  final String businessId;

  Color _tierColor() {
    switch (plan.tier) {
      case PlanTier.vip:
        return AgendaTokens.tierVip;
      case PlanTier.golden:
        return AgendaTokens.tierGolden;
      case PlanTier.plata:
        return AgendaTokens.tierPlata;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tenantId: tenantId, businessId: businessId);

    return ListTile(
      leading: plan.tier != null
          ? CircleAvatar(
              backgroundColor: _tierColor(),
              radius: 16,
              child: Text(
                plan.tier!.label[0],
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            )
          : null,
      title: Text(plan.nombrePlan),
      subtitle: Text(
        '${plan.tipo.label} · ${plan.totalCreditos} créditos · ${plan.validezDias} días · \$${plan.precio.toStringAsFixed(2)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!plan.activo)
            const Chip(
              label: Text('Inactivo'),
              visualDensity: VisualDensity.compact,
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                final result = await showDialog<PlanFormResult>(
                  context: context,
                  builder: (_) => PlanFormDialog(initial: plan),
                );
                if (result == null || !context.mounted) return;
                try {
                  await ref.read(plansProvider(key).notifier).update(
                        planId: plan.id,
                        nombrePlan: result.nombrePlan,
                        tipo: result.tipo,
                        tier: result.tier,
                        totalCreditos: result.totalCreditos,
                        validezDias: result.validezDias,
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
                    title: const Text('Eliminar plan'),
                    content: Text(
                        '¿Eliminar "${plan.nombrePlan}"? Se desactivará.'),
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
                      .read(plansProvider(key).notifier)
                      .delete(plan.id);
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
