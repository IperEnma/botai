import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

const List<String> kDayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

/// Tarjeta para configurar horario del negocio (días y franjas).
class BusinessHoursCard extends ConsumerStatefulWidget {
  final String tenantId;

  const BusinessHoursCard({super.key, required this.tenantId});

  @override
  ConsumerState<BusinessHoursCard> createState() => _BusinessHoursCardState();
}

class _BusinessHoursCardState extends ConsumerState<BusinessHoursCard> {
  List<TextEditingController> _openControllers = [];
  List<TextEditingController> _closeControllers = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 7; i++) {
      _openControllers.add(TextEditingController(text: ''));
      _closeControllers.add(TextEditingController(text: ''));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (var c in _openControllers) c.dispose();
    for (var c in _closeControllers) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.tenantId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final api = ref.read(apiServiceProvider);
      final list = await api.getBusinessHours(widget.tenantId);
      if (!mounted) return;
      for (var e in list) {
        final day = (e['dayOfWeek'] as num?)?.toInt();
        if (day == null || day < 1 || day > 7) continue;
        final i = day - 1;
        _openControllers[i].text = (e['openTime'] as String?) ?? '';
        _closeControllers[i].text = (e['closeTime'] as String?) ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (widget.tenantId.isEmpty) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final body = List.generate(7, (i) => {
        'dayOfWeek': i + 1,
        'openTime': _openControllers[i].text.trim().isEmpty ? null : _openControllers[i].text.trim(),
        'closeTime': _closeControllers[i].text.trim().isEmpty ? null : _closeControllers[i].text.trim(),
      });
      await api.saveBusinessHours(widget.tenantId, body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario guardado'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tenantId.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.schedule, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Text('Horario del negocio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              const SizedBox(width: 8),
              Text('(Selecciona un bot)', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Horario del negocio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Define en qué horario atiendes. Deja vacío = cerrado.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else
              Column(
                children: List.generate(7, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 90, child: Text(kDayNames[i], style: const TextStyle(fontWeight: FontWeight.w500))),
                      Expanded(
                        child: TextField(
                          controller: _openControllers[i],
                          decoration: const InputDecoration(labelText: 'Abre', hintText: '09:00', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _closeControllers[i],
                          decoration: const InputDecoration(labelText: 'Cierra', hintText: '18:00', isDense: true),
                        ),
                      ),
                    ],
                  ),
                )),
              ),
            const SizedBox(height: 12),
            if (!_loading)
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save, size: 18),
                label: Text(_saving ? 'Guardando...' : 'Guardar horario'),
              ),
          ],
        ),
      ),
    );
  }
}
