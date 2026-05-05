import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/category.dart';
import '../../../providers/agenda/platform/categories_admin_provider.dart';
import '../../../services/agenda_api_exception.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../theme/agenda_tokens.dart' show AgendaTokens;
import 'widgets/category_form_dialog.dart';

class CategoriesAdminScreen extends ConsumerWidget {
  const CategoriesAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoriesAdminProvider);

    return Scaffold(
      backgroundColor: AgendaTokens.surface,
      appBar: AppBar(
        backgroundColor: AgendaTokens.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Catálogo global de categorías', style: AgendaTokens.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ref.read(categoriesAdminProvider.notifier).load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
      body: _Body(state: state),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => const CategoryFormDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(categoriesAdminProvider.notifier).create(
            nombre: result.nombre,
            slug: result.slug,
            synonyms: result.synonyms,
            activo: result.activo,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría creada')),
        );
      }
    } on AgendaApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final CategoriesAdminState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.items.isEmpty) {
      return const AgendaLoadingView();
    }
    if (state.error != null && state.items.isEmpty) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: ref.read(categoriesAdminProvider.notifier).load,
      );
    }
    if (state.items.isEmpty) {
      return const AgendaEmptyState(
        icon: Icons.category_outlined,
        title: 'Sin categorías todavía',
        subtitle: 'Creá la primera categoría con el botón de abajo',
      );
    }
    return ListView.separated(
      padding: AgendaTokens.screenPadding,
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = state.items[index];
        return _CategoryRow(category: c);
      },
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.activo ? null : Colors.grey.shade300,
          child: Icon(
            category.activo ? Icons.label : Icons.label_off,
            color: Colors.white,
          ),
        ),
        title: Text(
          category.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('slug: ${category.slug}'),
            if (category.synonyms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'sinónimos: ${category.synonyms.join(", ")}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await _openEdit(context, ref);
            } else if (value == 'delete') {
              await _confirmDelete(context, ref);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => CategoryFormDialog(initial: category),
    );
    if (result == null) return;
    try {
      await ref.read(categoriesAdminProvider.notifier).update(
            id: category.id,
            nombre: result.nombre,
            slug: result.slug,
            synonyms: result.synonyms,
            activo: result.activo,
          );
    } on AgendaApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${category.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(categoriesAdminProvider.notifier).delete(category.id);
    } on AgendaApiException catch (e) {
      if (context.mounted) {
        final msg = e.isConflict
            ? 'No se puede eliminar: la categoría tiene negocios asociados.'
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }
}
