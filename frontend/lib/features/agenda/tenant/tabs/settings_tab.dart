import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/business_settings.dart';
import '../../../../providers/agenda/tenant_admin_resolved_provider.dart';
import '../../../../providers/agenda/tenant/settings_provider.dart';
import '../../../../providers/agenda/agenda_api_provider.dart';
import '../../../../services/agenda_api_exception.dart';

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
  late final TextEditingController _alertDaysCtrl;
  late final TextEditingController _alertCreditsCtrl;
  bool _autoNotify = false;
  bool _requireBookingConfirmation = true;

  bool _initialized = false;

  ({String tenantId, String businessId}) get _key =>
      (tenantId: widget.tenantId, businessId: widget.businessId);

  @override
  void initState() {
    super.initState();
    _cancellationCtrl = TextEditingController();
    _alertDaysCtrl = TextEditingController();
    _alertCreditsCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _cancellationCtrl.dispose();
    _alertDaysCtrl.dispose();
    _alertCreditsCtrl.dispose();
    super.dispose();
  }

  void _populate(BusinessSettings s) {
    if (_initialized) return;
    _initialized = true;
    _cancellationCtrl.text = s.hoursCancellationLimit.toString();
    _alertDaysCtrl.text = s.expirationAlertDays.toString();
    _alertCreditsCtrl.text = s.expirationAlertCredits.toString();
    setState(() {
      _autoNotify = s.autoNotifyEnabled;
      _requireBookingConfirmation = s.requireBookingConfirmation;
    });
  }

  Future<void> _save(BusinessSettings current) async {
    if (!_formKey.currentState!.validate()) return;
    final updated = current.copyWith(
      hoursCancellationLimit: int.parse(_cancellationCtrl.text.trim()),
      expirationAlertDays: int.parse(_alertDaysCtrl.text.trim()),
      expirationAlertCredits: int.parse(_alertCreditsCtrl.text.trim()),
      autoNotifyEnabled: _autoNotify,
      requireBookingConfirmation: _requireBookingConfirmation,
    );
    await ref.read(settingsProvider(_key).notifier).save(updated);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Configuración guardada')));
    }
  }

  Future<void> _linkIdentifierDialog({required bool linkEmail}) async {
    final ctrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    Future<void> submit() async {
      final raw = ctrl.text.trim();
      if (raw.isEmpty) return;
      try {
        final api = ref.read(agendaApiServiceProvider);
        await api.linkTenantIdentifier(
          email: linkEmail ? raw : null,
          numero: linkEmail ? null : raw,
        );
        ref.invalidate(tenantAdminResolvedProvider);
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(
          content: Text(linkEmail
              ? 'Email vinculado al negocio.'
              : 'Número vinculado al negocio.'),
        ));
        // Si el vínculo cambió el tenant, la invalidación actualizará /home.
        // Dejamos al usuario en settings.
      } on AgendaApiException catch (e) {
        messenger.showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      } catch (e) {
        messenger.showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(linkEmail ? 'Agregar email' : 'Agregar WhatsApp'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
              linkEmail ? TextInputType.emailAddress : TextInputType.phone,
          decoration: InputDecoration(
            hintText: linkEmail ? 'correo@dominio.com' : '+598 99 112 233',
          ),
          onSubmitted: (_) {
            Navigator.of(dialogCtx).pop();
            submit();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              submit();
            },
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
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
            Text('Cuenta', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _linkIdentifierDialog(linkEmail: false),
                  icon: const Icon(Icons.phone),
                  label: const Text('Agregar WhatsApp'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _linkIdentifierDialog(linkEmail: true),
                  icon: const Icon(Icons.alternate_email),
                  label: const Text('Agregar email'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Cancelación',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _NumField(
              controller: _cancellationCtrl,
              label: 'Horas límite de cancelación *',
              min: 0,
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
              value: _requireBookingConfirmation,
              onChanged: (v) => setState(() => _requireBookingConfirmation = v),
              title: const Text('Confirmar reservas manualmente'),
              subtitle: const Text(
                'Si está activo, las reservas quedan pendientes hasta que las confirmes.',
              ),
              contentPadding: EdgeInsets.zero,
            ),
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
