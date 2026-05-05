import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/business.dart';
import '../../../../providers/agenda/public/public_categories_provider.dart';
import '../../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';
import '../widgets/category_multi_select_dialog.dart';

class CategoriesTab extends ConsumerWidget {
  const CategoriesTab({
    super.key,
    required this.tenantId,
    required this.business,
  });

  final String tenantId;
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(publicCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const AgendaLoadingView(),
      error: (e, _) => AgendaErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(publicCategoriesProvider),
      ),
      data: (allCategories) {
        final associated = business.categorias;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categorías asociadas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (associated.isEmpty)
                const Text('Sin categorías asociadas.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      associated.map((slug) => Chip(label: Text(slug))).toList(),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Editar categorías'),
                onPressed: () async {
                  final selectedIds = await CategoryMultiSelectDialog.show(
                    context,
                    allCategories: allCategories,
                    selectedSlugs: associated,
                  );
                  if (selectedIds == null || !context.mounted) return;
                  try {
                    await ref
                        .read(businessesProvider(tenantId).notifier)
                        .associateCategories(
                          businessId: business.id,
                          categoryIds: selectedIds,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Categorías actualizadas')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
