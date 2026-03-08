import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/service.dart';
import '../../providers/auth_provider.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  final String botId;
  final String tenantId;
  final bool embedded;

  const ServicesScreen({
    super.key,
    required this.botId,
    required this.tenantId,
    this.embedded = false,
  });

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  List<Service> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final list = await api.getServices(widget.tenantId);
      if (mounted) {
        setState(() {
          _services = list;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _save(Service s, {bool isNew = false}) async {
    try {
      final api = ref.read(apiServiceProvider);
      if (isNew || s.id == null || s.id!.isEmpty) {
        await api.createService(widget.tenantId, {
          'name': s.name,
          'sortOrder': s.sortOrder,
          'active': s.active,
        });
      } else {
        await api.updateService(widget.tenantId, s.id!, {
          'name': s.name,
          'sortOrder': s.sortOrder,
          'active': s.active,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio guardado'), backgroundColor: AppTheme.successColor),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _delete(Service s) async {
    if (s.id == null || s.id!.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: Text('¿Eliminar "${s.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteService(widget.tenantId, s.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio eliminado'), backgroundColor: AppTheme.successColor),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDialog({Service? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final orderController = TextEditingController(
      text: (existing?.sortOrder ?? _services.length).toString(),
    );
    bool active = existing?.active ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Editar servicio' : 'Nuevo servicio'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del servicio',
                    hintText: 'Ej: Corte de cabello, Manicura',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Orden',
                    hintText: '0',
                  ),
                ),
                if (existing != null) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Activo'),
                    value: active,
                    onChanged: (v) => setDialogState(() => active = v ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final sortOrder = int.tryParse(orderController.text.trim()) ?? _services.length;
                final s = Service(
                  id: existing?.id,
                  tenantId: widget.tenantId,
                  name: nameController.text.trim(),
                  sortOrder: sortOrder,
                  active: active,
                );
                Navigator.pop(ctx);
                _save(s, isNew: existing == null);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.build_circle, color: Colors.teal),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Servicios del negocio',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Servicios ofrecidos; el bot y la IA los usan para agendar y en el RAG',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = _services[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: s.active ? Colors.teal.withValues(alpha: 0.2) : Colors.grey,
                          child: Text('${index + 1}', style: TextStyle(color: s.active ? Colors.teal : Colors.grey[600])),
                        ),
                        title: Text(s.name),
                        subtitle: Text(s.active ? 'Orden: ${s.sortOrder}' : 'Inactivo · Orden: ${s.sortOrder}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(existing: s)),
                            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(s)),
                          ],
                        ),
                      );
                    },
                  ),
                  if (_services.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No hay servicios. Agrega al menos uno para que el bot pueda ofrecer agendar.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Servicios')),
      body: content,
    );
  }
}
