import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../models/agenda/category.dart';
import '../../theme/agenda_tokens.dart';

class CategoryFormResult {
  final String nombre;
  final String slug;
  final List<String> synonyms;
  final bool activo;

  const CategoryFormResult({
    required this.nombre,
    required this.slug,
    required this.synonyms,
    required this.activo,
  });
}

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({super.key, this.initial});

  final Category? initial;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _slug;
  late final TextEditingController _synonymInput;
  late final List<String> _synonyms;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?.nombre ?? '');
    _slug = TextEditingController(text: widget.initial?.slug ?? '');
    _synonymInput = TextEditingController();
    _synonyms = [...?widget.initial?.synonyms];
    _activo = widget.initial?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _slug.dispose();
    _synonymInput.dispose();
    super.dispose();
  }

  void _addSynonym() {
    final s = _synonymInput.text.trim().toLowerCase();
    if (s.isEmpty) return;
    if (_synonyms.contains(s)) return;
    setState(() {
      _synonyms.add(s);
      _synonymInput.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(CategoryFormResult(
      nombre: _nombre.text.trim(),
      slug: _slug.text.trim().toLowerCase(),
      synonyms: List.unmodifiable(_synonyms),
      activo: _activo,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AgendaTokens.dialogRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'Editar categoría' : 'Nueva categoría',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _slug,
                  decoration: const InputDecoration(
                    labelText: 'Slug',
                    helperText: 'Identificador URL-safe (sin espacios)',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim())) {
                      return 'Solo minúsculas, números y "-"';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Sinónimos',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in _synonyms)
                      Chip(
                        label: Text(s),
                        onDeleted: () => setState(() => _synonyms.remove(s)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _synonymInput,
                        decoration: const InputDecoration(
                          hintText: 'Agregar sinónimo y Enter',
                        ),
                        onSubmitted: (_) => _addSynonym(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addSynonym,
                      icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activa'),
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(isEdit ? 'Guardar' : 'Crear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
