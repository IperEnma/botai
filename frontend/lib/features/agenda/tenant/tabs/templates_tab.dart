import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/notification_template.dart';
import '../../../../providers/agenda/tenant/templates_provider.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';

class TemplatesTab extends ConsumerWidget {
  const TemplatesTab({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tenantId: tenantId, businessId: businessId);
    final state = ref.watch(templatesProvider(key));

    if (state.isLoading) return const AgendaLoadingView();
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(templatesProvider(key).notifier).load(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'templates_fab',
        onPressed: () => _onCreate(context, ref, key),
        child: const Icon(Icons.add),
      ),
      body: state.items.isEmpty
          ? const AgendaEmptyState(
              icon: Icons.message_outlined,
              title: 'Sin plantillas',
              subtitle: 'Creá plantillas de notificación con el botón +',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _TemplateRow(
                template: state.items[i],
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
    final result = await showDialog<_TemplateFormResult>(
      context: context,
      builder: (_) => const _TemplateFormDialog(),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(templatesProvider(key).notifier).create(
            codigo: result.codigo,
            canal: result.canal,
            titulo: result.titulo,
            cuerpo: result.cuerpo,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _TemplateRow extends ConsumerWidget {
  const _TemplateRow({
    required this.template,
    required this.tenantId,
    required this.businessId,
  });

  final NotificationTemplate template;
  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tenantId: tenantId, businessId: businessId);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
        child: const Icon(Icons.message_outlined,
            color: Color(0xFF6366F1), size: 18),
      ),
      title: Text(template.titulo),
      subtitle: Text('${template.codigo} · ${template.canal.label}'),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'edit') {
            final result = await showDialog<_TemplateFormResult>(
              context: context,
              builder: (_) => _TemplateFormDialog(initial: template),
            );
            if (result == null || !context.mounted) return;
            try {
              await ref.read(templatesProvider(key).notifier).update(
                    id: template.id,
                    codigo: result.codigo,
                    titulo: result.titulo,
                    cuerpo: result.cuerpo,
                    canal: result.canal,
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
                title: const Text('Eliminar plantilla'),
                content: Text(
                    '¿Eliminar la plantilla "${template.codigo}"?'),
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
                  .read(templatesProvider(key).notifier)
                  .delete(template.id);
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
    );
  }
}

class _TemplateFormResult {
  final String codigo;
  final NotificationCanal canal;
  final String titulo;
  final String cuerpo;

  const _TemplateFormResult({
    required this.codigo,
    required this.canal,
    required this.titulo,
    required this.cuerpo,
  });
}

class _TemplateFormDialog extends StatefulWidget {
  const _TemplateFormDialog({this.initial});

  final NotificationTemplate? initial;

  @override
  State<_TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<_TemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _cuerpoCtrl;
  late NotificationCanal _canal;

  @override
  void initState() {
    super.initState();
    _codigoCtrl =
        TextEditingController(text: widget.initial?.codigo ?? '');
    _tituloCtrl =
        TextEditingController(text: widget.initial?.titulo ?? '');
    _cuerpoCtrl =
        TextEditingController(text: widget.initial?.cuerpo ?? '');
    _canal = widget.initial?.canal ?? NotificationCanal.email;
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _tituloCtrl.dispose();
    _cuerpoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar plantilla' : 'Nueva plantilla'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEdit)
                TextFormField(
                  controller: _codigoCtrl,
                  decoration: const InputDecoration(labelText: 'Código *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
              if (!isEdit) const SizedBox(height: 12),
              DropdownButtonFormField<NotificationCanal>(
                value: _canal,
                decoration: const InputDecoration(labelText: 'Canal'),
                items: NotificationCanal.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _canal = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cuerpoCtrl,
                decoration: const InputDecoration(labelText: 'Cuerpo *'),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _TemplateFormResult(
                codigo: _codigoCtrl.text.trim(),
                canal: _canal,
                titulo: _tituloCtrl.text.trim(),
                cuerpo: _cuerpoCtrl.text.trim(),
              ),
            );
          },
          child: Text(isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
