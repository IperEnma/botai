import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/agenda_tokens.dart';

import '../../../models/agenda/business.dart';
import '../../../models/agenda/business_settings.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../providers/agenda/tenant/settings_provider.dart';
import '../../../providers/agenda/tenant_admin_resolved_provider.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../services/agenda_api_exception.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

class BusinessDetailScreen extends ConsumerWidget {
  const BusinessDetailScreen({
    super.key,
    required this.tenantId,
    required this.businessId,
    this.initialTabIndex = 0,
  });

  final String tenantId;
  final String businessId;
  final int    initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(businessesProvider(tenantId));

    if (state.isLoading) return const Scaffold(body: AgendaLoadingView());
    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AgendaTokens.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text('Negocio', style: AgendaTokens.appBarTitle),
        ),
        body: AgendaErrorView(
          message: state.error!,
          onRetry: () => ref.read(businessesProvider(tenantId).notifier).load(),
        ),
      );
    }

    final business = state.items.where((b) => b.id == businessId).firstOrNull;
    if (business == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AgendaTokens.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text('Negocio', style: AgendaTokens.appBarTitle),
        ),
        body: const AgendaEmptyState(
          icon: Icons.store_mall_directory_outlined,
          title: 'Negocio no encontrado',
          subtitle: 'Es posible que haya sido eliminado.',
        ),
      );
    }

    return _BusinessConfigView(tenantId: tenantId, business: business);
  }
}

// ── Config page ───────────────────────────────────────────────────────────────

class _BusinessConfigView extends ConsumerStatefulWidget {
  const _BusinessConfigView({
    required this.tenantId,
    required this.business,
  });

  final String   tenantId;
  final Business business;

  @override
  ConsumerState<_BusinessConfigView> createState() => _BusinessConfigViewState();
}

class _BusinessConfigViewState extends ConsumerState<_BusinessConfigView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _cancellationCtrl;
  late final TextEditingController _alertDaysCtrl;
  late final TextEditingController _alertCreditsCtrl;
  bool _autoNotify  = false;
  bool _requireBookingConfirmation = true;
  bool _initialized = false;

  ({String tenantId, String businessId}) get _key =>
      (tenantId: widget.tenantId, businessId: widget.business.id);

  @override
  void initState() {
    super.initState();
    _cancellationCtrl = TextEditingController();
    _alertDaysCtrl    = TextEditingController();
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
    _alertDaysCtrl.text    = s.expirationAlertDays.toString();
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
      expirationAlertDays:    int.parse(_alertDaysCtrl.text.trim()),
      expirationAlertCredits: int.parse(_alertCreditsCtrl.text.trim()),
      autoNotifyEnabled:      _autoNotify,
      requireBookingConfirmation: _requireBookingConfirmation,
    );
    await ref.read(settingsProvider(_key).notifier).save(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
    }
  }

  Future<void> _linkIdentifierDialog({required bool linkEmail}) async {
    final ctrl      = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    Future<void> submit() async {
      final raw = ctrl.text.trim();
      if (raw.isEmpty) return;
      try {
        final api = ref.read(agendaApiServiceProvider);
        await api.linkTenantIdentifier(
          email:  linkEmail ? raw : null,
          numero: linkEmail ? null : raw,
        );
        ref.invalidate(tenantAdminResolvedProvider);
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(
          content: Text(linkEmail
              ? 'Email vinculado al negocio.'
              : 'Número vinculado al negocio.'),
        ));
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
    final settingsState = ref.watch(settingsProvider(_key));

    if (settingsState.settings != null) _populate(settingsState.settings!);

    return Scaffold(
      backgroundColor: AgendaTokens.surface,
      appBar: AppBar(
        backgroundColor: AgendaTokens.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.business.nombre, style: AgendaTokens.appBarTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Configuración del perfil ─────────────────────────────────
              _SectionLabel('CONFIGURACIÓN DEL PERFIL'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
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
              ),

              const SizedBox(height: 36),

              // ── Configuración de seguridad ───────────────────────────────
              _SectionLabel('CONFIGURACIÓN DE SEGURIDAD'),
              const SizedBox(height: 12),
              if (settingsState.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: CircularProgressIndicator(),
                )
              else if (settingsState.error != null && settingsState.settings == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AgendaErrorView(
                    message: settingsState.error!,
                    onRetry: () =>
                        ref.read(settingsProvider(_key).notifier).load(),
                  ),
                )
              else if (settingsState.settings != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NumField(
                        controller: _cancellationCtrl,
                        label: 'Horas límite de cancelación *',
                        min: 0,
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 4),
                      SwitchListTile(
                        value: _requireBookingConfirmation,
                        onChanged: (v) =>
                            setState(() => _requireBookingConfirmation = v),
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
                      if (settingsState.error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          settingsState.error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: settingsState.isSaving
                            ? null
                            : () => _save(settingsState.settings!),
                        child: settingsState.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Guardar configuración'),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        style: AgendaTokens.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AgendaTokens.primary.withValues(alpha: 0.75),
          letterSpacing: 0.8,
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
  final int    min;

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
