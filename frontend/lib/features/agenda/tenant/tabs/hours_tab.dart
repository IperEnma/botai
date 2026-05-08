import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/business_hours.dart';
import '../../../../providers/agenda/tenant/business_hours_provider.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';

class HoursTab extends ConsumerStatefulWidget {
  const HoursTab({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  ConsumerState<HoursTab> createState() => _HoursTabState();
}

class _HoursTabState extends ConsumerState<HoursTab> {
  // Local editable copy: one entry per day 0-6
  late List<_DayEdit> _days;
  bool _initialized = false;

  ({String tenantId, String businessId}) get _key =>
      (tenantId: widget.tenantId, businessId: widget.businessId);

  @override
  void initState() {
    super.initState();
    // Placeholder hasta el primer GET: no fingir días “abiertos” (evita parecer mock).
    _days = List.generate(
      7,
      (i) => _DayEdit(diaSemana: i, cerrado: true, apertura: '09:00', cierre: '18:00'),
    );
  }

  void _syncFromProvider(List<BusinessHours> hours) {
    if (_initialized) return;
    _initialized = true;
    final map = {for (final h in hours) h.diaSemana: h};
    _days = List.generate(7, (i) {
      final h = map[i];
      if (h == null) {
        // Sin fila en backend = ese día no está configurado → cerrado, no 9–18 encendido.
        return _DayEdit(diaSemana: i, cerrado: true, apertura: '09:00', cierre: '18:00');
      }
      return _DayEdit(
        diaSemana: i,
        cerrado: h.cerrado,
        apertura: h.apertura ?? '09:00',
        cierre: h.cierre ?? '18:00',
      );
    });
  }

  Future<void> _save() async {
    final hours = _days
        .map((d) => BusinessHours(
              id: '',
              businessId: widget.businessId,
              diaSemana: d.diaSemana,
              apertura: d.cerrado ? null : d.apertura,
              cierre: d.cerrado ? null : d.cierre,
              cerrado: d.cerrado,
            ))
        .toList();

    final ok = await ref.read(businessHoursProvider(_key).notifier).save(hours);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Horarios guardados' : 'Error al guardar'),
      backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
    ));
  }

  Future<void> _pickTime(int dayIndex, bool isApertura) async {
    final current = isApertura ? _days[dayIndex].apertura : _days[dayIndex].cierre;
    final parts = current.split(':');
    final initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0);

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isApertura) {
        _days[dayIndex] = _days[dayIndex].copyWith(apertura: formatted);
      } else {
        _days[dayIndex] = _days[dayIndex].copyWith(cierre: formatted);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessHoursProvider(_key));

    if (state.isLoading) return const AgendaLoadingView(message: 'Cargando horarios…');
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(businessHoursProvider(_key).notifier).load(),
      );
    }

    // Un solo sync tras respuesta OK (vacía o con filas): lista vacía => todos cerrados.
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _syncFromProvider(state.hours));
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'hours_fab',
        onPressed: state.isSaving ? null : _save,
        icon: state.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_outlined),
        label: Text(state.isSaving ? 'Guardando…' : 'Guardar horarios'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: 7,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final day = _days[i];
          return _DayRow(
            day: day,
            onToggleCerrado: (v) => setState(() {
              _days[i] = day.copyWith(cerrado: v);
            }),
            onPickApertura: () => _pickTime(i, true),
            onPickCierre: () => _pickTime(i, false),
          );
        },
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.onToggleCerrado,
    required this.onPickApertura,
    required this.onPickCierre,
  });

  final _DayEdit day;
  final ValueChanged<bool> onToggleCerrado;
  final VoidCallback onPickApertura;
  final VoidCallback onPickCierre;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              BusinessHours.dayNames[day.diaSemana],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Switch(value: !day.cerrado, onChanged: (v) => onToggleCerrado(!v)),
          if (day.cerrado)
            const Expanded(
              child: Text('Cerrado',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else ...[
            const SizedBox(width: 8),
            _TimeButton(label: day.apertura, onTap: onPickApertura),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('–', style: TextStyle(fontSize: 16)),
            ),
            _TimeButton(label: day.cierre, onTap: onPickCierre),
          ],
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(70, 36),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _DayEdit {
  final int diaSemana;
  final bool cerrado;
  final String apertura;
  final String cierre;

  const _DayEdit({
    required this.diaSemana,
    required this.cerrado,
    required this.apertura,
    required this.cierre,
  });

  _DayEdit copyWith({bool? cerrado, String? apertura, String? cierre}) =>
      _DayEdit(
        diaSemana: diaSemana,
        cerrado: cerrado ?? this.cerrado,
        apertura: apertura ?? this.apertura,
        cierre: cierre ?? this.cierre,
      );
}
