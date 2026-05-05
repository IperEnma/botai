import 'package:flutter/material.dart';

import '../../../../models/agenda/category.dart';

/// Diálogo de selección múltiple de categorías del catálogo global.
/// Retorna la lista de IDs seleccionados, o null si se cancela.
class CategoryMultiSelectDialog extends StatefulWidget {
  const CategoryMultiSelectDialog({
    super.key,
    required this.allCategories,
    required this.selectedSlugs,
  });

  final List<Category> allCategories;
  final List<String> selectedSlugs;

  static Future<List<String>?> show(
    BuildContext context, {
    required List<Category> allCategories,
    required List<String> selectedSlugs,
  }) {
    return showDialog<List<String>>(
      context: context,
      builder: (_) => CategoryMultiSelectDialog(
        allCategories: allCategories,
        selectedSlugs: selectedSlugs,
      ),
    );
  }

  @override
  State<CategoryMultiSelectDialog> createState() =>
      _CategoryMultiSelectDialogState();
}

class _CategoryMultiSelectDialogState
    extends State<CategoryMultiSelectDialog> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.allCategories
        .where((c) => widget.selectedSlugs.contains(c.slug))
        .map((c) => c.id)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asociar categorías'),
      content: SizedBox(
        width: 400,
        child: widget.allCategories.isEmpty
            ? const Text('No hay categorías disponibles.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.allCategories.length,
                itemBuilder: (_, i) {
                  final cat = widget.allCategories[i];
                  return CheckboxListTile(
                    value: _selectedIds.contains(cat.id),
                    title: Text(cat.nombre),
                    subtitle: Text(cat.slug,
                        style: Theme.of(context).textTheme.bodySmall),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedIds.add(cat.id);
                        } else {
                          _selectedIds.remove(cat.id);
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
