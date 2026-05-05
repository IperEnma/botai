import 'package:flutter/material.dart';

import '../../../../models/agenda/agenda_service.dart';

class ServiceFormResult {
  final String nombre;
  final String? descripcion;
  final int duracionMin;
  final double precio;
  final bool activo;

  const ServiceFormResult({
    required this.nombre,
    this.descripcion,
    required this.duracionMin,
    required this.precio,
    required this.activo,
  });
}

class ServiceFormDialog extends StatefulWidget {
  const ServiceFormDialog({super.key, this.initial});

  final AgendaService? initial;

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _duracionCtrl;
  late final TextEditingController _precioCtrl;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initial?.nombre ?? '');
    _descripcionCtrl =
        TextEditingController(text: widget.initial?.descripcion ?? '');
    _duracionCtrl = TextEditingController(
        text: widget.initial?.duracionMin.toString() ?? '60');
    _precioCtrl = TextEditingController(
        text: widget.initial?.precio.toStringAsFixed(2) ?? '');
    _activo = widget.initial?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _duracionCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(ServiceFormResult(
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
      duracionMin: int.parse(_duracionCtrl.text.trim()),
      precio: double.parse(_precioCtrl.text.trim()),
      activo: _activo,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar servicio' : 'Nuevo servicio'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _duracionCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Duración (min) *'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Ingresá minutos válidos';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl,
                      decoration: const InputDecoration(labelText: 'Precio *'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0) return 'Precio inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (isEdit) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                  title: const Text('Activo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
