import 'package:flutter/material.dart';

import '../../../../models/agenda/plan.dart';
import '../../theme/agenda_tokens.dart';

class PlanFormResult {
  final String nombrePlan;
  final PlanTipo tipo;
  final PlanTier? tier;
  final int totalCreditos;
  final int validezDias;
  final double precio;
  final bool activo;

  const PlanFormResult({
    required this.nombrePlan,
    required this.tipo,
    this.tier,
    required this.totalCreditos,
    required this.validezDias,
    required this.precio,
    required this.activo,
  });
}

class PlanFormDialog extends StatefulWidget {
  const PlanFormDialog({super.key, this.initial});

  final Plan? initial;

  @override
  State<PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _creditosCtrl;
  late final TextEditingController _validezCtrl;
  late final TextEditingController _precioCtrl;
  late PlanTipo _tipo;
  PlanTier? _tier;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initial?.nombrePlan ?? '');
    _creditosCtrl = TextEditingController(
        text: widget.initial?.totalCreditos.toString() ?? '10');
    _validezCtrl = TextEditingController(
        text: widget.initial?.validezDias.toString() ?? '30');
    _precioCtrl = TextEditingController(
        text: widget.initial?.precio.toStringAsFixed(2) ?? '');
    _tipo = widget.initial?.tipo ?? PlanTipo.porCreditos;
    _tier = widget.initial?.tier;
    _activo = widget.initial?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _creditosCtrl.dispose();
    _validezCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  Color _tierColor(PlanTier? t) {
    switch (t) {
      case PlanTier.vip:
        return AgendaTokens.tierVip;
      case PlanTier.golden:
        return AgendaTokens.tierGolden;
      case PlanTier.plata:
        return AgendaTokens.tierPlata;
      default:
        return Colors.grey;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(PlanFormResult(
      nombrePlan: _nombreCtrl.text.trim(),
      tipo: _tipo,
      tier: _tier,
      totalCreditos: int.parse(_creditosCtrl.text.trim()),
      validezDias: int.parse(_validezCtrl.text.trim()),
      precio: double.parse(_precioCtrl.text.trim()),
      activo: _activo,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar plan' : 'Nuevo plan'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nombre del plan *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PlanTipo>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(labelText: 'Tipo *'),
                  items: PlanTipo.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _tipo = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PlanTier?>(
                  initialValue: _tier,
                  decoration:
                      const InputDecoration(labelText: 'Tier (opcional)'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Sin tier')),
                    ...PlanTier.values.map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _tierColor(t),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(t.label),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _tier = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _creditosCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Créditos *'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 0) return 'Valor inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _validezCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Validez (días) *'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) return 'Mínimo 1 día';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _precioCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Precio *'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
