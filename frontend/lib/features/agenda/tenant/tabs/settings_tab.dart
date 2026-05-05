import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/business_settings.dart';
import '../../../../providers/agenda/tenant/settings_provider.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each field
  late final TextEditingController _cancellationCtrl;
  late final TextEditingController _loyaltyMinCtrl;
  late final TextEditingController _loyaltyWindowCtrl;
  late final TextEditingController _alertDaysCtrl;
  late final TextEditingController _alertCreditsCtrl;
  bool _autoNotify = false;

  bool _initialized = false;

  ({String tenantId, String businessId}) get _key =>
      (tenantId: widget.tenantId, businessId: widget.businessId);

  @override
  void initState() {
    super.initState();
    _cancellationCtrl = TextEditingController();
    _loyaltyMinCtrl = TextEditingController();
    _loyaltyWindowCtrl = TextEditingController();
    _alertDaysCtrl = TextEditingController();
    _alertCreditsCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _cancellationCtrl.dispose();
    _loyaltyMinCtrl.dispose();
    _loyaltyWindowCtrl.dispose();
    _alertDaysCtrl.dispose();
    _alertCreditsCtrl.dispose();
    super.dispose();
  }

  void _populate(BusinessSettings s) {
    if (_initialized) return;
    _initialized = true;
    _cancellationCtrl.text = s.hoursCancellationLimit.toString();
    _loyaltyMinCtrl.text = s.loyaltyMinAttendances.toString();
    _loyaltyWindowCtrl.text = s.loyaltyWindowDays.toString();
    _alertDaysCtrl.text = s.expirationAlertDays.toString();
    _alertCreditsCtrl.text = s.expirationAlertCredits.toString();
    setState(() => _autoNotify = s.autoNotifyEnabled);
  }

  Future<void> _save(BusinessSettings current) async {
    if (!_formKey.currentState!.validate()) return;
    final updated = current.copyWith(
      hoursCancellationLimit: int.parse(_cancellationCtrl.text.trim()),
      loyaltyMinAttendances: int.parse(_loyaltyMinCtrl.text.trim()),
      loyaltyWindowDays: int.parse(_loyaltyWindowCtrl.text.trim()),
      expirationAlertDays: int.parse(_alertDaysCtrl.text.trim()),
      expirationAlertCredits: int.parse(_alertCreditsCtrl.text.trim()),
      autoNotifyEnabled: _autoNotify,
    );
    await ref.read(settingsProvider(_key).notifier).save(updated);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Configuración guardada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider(_key));

    if (state.isLoading) return const AgendaLoadingView();
    if (state.error != null && state.settings == null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(settingsProvider(_key).notifier).load(),
      );
    }

    final settings = state.settings!;
    _populate(settings);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancelación',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _NumField(
              controller: _cancellationCtrl,
              label: 'Horas límite de cancelación *',
              min: 0,
            ),
            const SizedBox(height: 20),
            Text('Fidelización',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumField(
                    controller: _loyaltyMinCtrl,
                    label: 'Asistencias mínimas *',
                    min: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumField(
                    controller: _loyaltyWindowCtrl,
                    label: 'Ventana (días) *',
                    min: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Alertas de vencimiento',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumField(
                    controller: _alertDaysCtrl,
                    label: 'Días antes de alertar *',
                    min: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumField(
                    controller: _alertCreditsCtrl,
                    label: 'Créditos mínimos para alertar *',
                    min: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _autoNotify,
              onChanged: (v) => setState(() => _autoNotify = v),
              title: const Text('Notificaciones automáticas'),
              contentPadding: EdgeInsets.zero,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(state.error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.isSaving ? null : () => _save(settings),
              child: state.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar configuración'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.label,
    required this.min,
  });

  final TextEditingController controller;
  final String label;
  final int min;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null || n < min) return 'Mínimo $min';
        return null;
      },
    );
  }
}
