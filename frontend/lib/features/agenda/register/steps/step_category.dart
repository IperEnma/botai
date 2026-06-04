import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/category.dart';
import '../../../../providers/agenda/public/public_categories_provider.dart';
import '../konecta_tokens.dart';
import '../widgets/conversational_input.dart';
import '../widgets/step_scaffold.dart';
import '../widgets/summary_card.dart';

class StepCategory extends ConsumerStatefulWidget {
  const StepCategory({
    super.key,
    required this.value,
    required this.onChanged,
    required this.summaryName,
    required this.summaryDepartment,
    required this.summaryLocality,
  });

  final List<Category> value;
  final ValueChanged<List<Category>> onChanged;
  final String? summaryName;
  final String? summaryDepartment;
  final String? summaryLocality;

  @override
  ConsumerState<StepCategory> createState() => _StepCategoryState();
}

class _StepCategoryState extends ConsumerState<StepCategory> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  List<Category> _selected = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.value);
    _ctrl = TextEditingController(text: _selectedText);
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _selectedText => _selected.map((c) => c.nombre).join(', ');

  List<Category> _suggestions(List<Category> all) {
    final available = all.where((c) => !_selected.any((s) => s.id == c.id));
    final q = _query.toLowerCase().trim();
    if (q.isEmpty) return available.take(5).toList();
    return available
        .where((c) => c.nombre.toLowerCase().contains(q))
        .take(5)
        .toList();
  }

  void _selectCategory(Category cat, List<Category> all) {
    final isSelected = _selected.any((c) => c.id == cat.id);
    final List<Category> newSelected;
    if (isSelected) {
      newSelected = _selected.where((c) => c.id != cat.id).toList();
    } else if (_selected.length >= 3) {
      return;
    } else {
      newSelected = [..._selected, cat];
    }

    setState(() {
      _selected = newSelected;
      _query = '';
    });

    _ctrl.text = newSelected.map((c) => c.nombre).join(', ');
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);

    widget.onChanged(newSelected);
  }

  void _onInputChanged(String text, List<Category> all) {
    final parts = text.split(',');
    final q = parts.last.trim();
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(publicCategoriesProvider);

    return StepScaffold(
      eyebrow: 'PASO 04 — CATEGORÍA',
      question: '¿A qué se dedica\ntu negocio?',
      hint: 'Opcional. Hasta 3 categorías.',
      input: categoriesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Text(
          'Error al cargar categorías',
          style: KTokens.tHint.copyWith(color: KTokens.errorColor),
        ),
        data: (categories) {
          final suggestions = _suggestions(categories);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConversationalInput(
                controller: _ctrl,
                focusNode: _focus,
                hintText: 'Ej: Peluquería, Medicina…',
                metaLeft: _selected.isEmpty
                    ? 'categoría'
                    : 'categoría · ${_selected.length}/3',
                autofocus: false,
                onChanged: (v) => _onInputChanged(v, categories),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selected.map(
                    (cat) => _CategoryChip(
                      label: cat.nombre,
                      selected: true,
                      onTap: () => _selectCategory(cat, categories),
                    ),
                  ),
                  if (_selected.length < 3)
                    ...suggestions.map(
                      (cat) => _CategoryChip(
                        label: cat.nombre,
                        selected: false,
                        onTap: () => _selectCategory(cat, categories),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
      summary: SummaryCard(
        rows: [
          SummaryRow(label: 'Negocio', value: widget.summaryName),
          SummaryRow(label: 'Departamento', value: widget.summaryDepartment),
          SummaryRow(label: 'Localidad', value: widget.summaryLocality),
          const SummaryRow(label: 'Categoría', current: true),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? KTokens.accentSoft : KTokens.surface,
          borderRadius: BorderRadius.circular(KTokens.rPill),
          border: Border.all(
            color: selected ? KTokens.accent : KTokens.borderStrong,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: KTokens.tCta.copyWith(
                color: selected ? KTokens.accent : KTokens.ink,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.close, size: 13, color: KTokens.accent),
            ],
          ],
        ),
      ),
    );
  }
}
