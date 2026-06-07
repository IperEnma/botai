import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/agenda_phone.dart';
import '../../../models/agenda/business.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/public/public_client_session_provider.dart';
import '../../../widgets/agenda_phone_field.dart';
import 'public_reservar_layout.dart';

/// Verificación WhatsApp mínima antes de acciones que requieren cuenta (ej. favoritos).
Future<bool> showPublicPhoneVerifySheet({
  required BuildContext context,
  required Business business,
  required String slug,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PublicPhoneVerifySheet(
      business: business,
      slug: slug,
    ),
  );
  return result == true;
}

class PublicPhoneVerifySheet extends ConsumerStatefulWidget {
  const PublicPhoneVerifySheet({
    super.key,
    required this.business,
    required this.slug,
  });

  final Business business;
  final String slug;

  @override
  ConsumerState<PublicPhoneVerifySheet> createState() =>
      _PublicPhoneVerifySheetState();
}

class _PublicPhoneVerifySheetState extends ConsumerState<PublicPhoneVerifySheet> {
  final _formKey = GlobalKey<FormState>();
  final _telCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _codeStep = false;
  bool _submitting = false;
  String? _otpError;
  String? _otpHint;

  PublicReservarTheme get _theme => PublicReservarTheme.felito();

  @override
  void dispose() {
    _telCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final telefono = normalizeAgendaPhoneDigits(_telCtrl.text);
    if (!isValidAgendaPhone(telefono)) {
      _snack('Ingresá un teléfono válido con código de país.');
      return;
    }

    setState(() {
      _submitting = true;
      _otpError = null;
    });
    try {
      final api = ref.read(agendaApiServiceProvider);
      final result = await api.sendPublicPhoneVerification(
        businessId: widget.business.id,
        telefono: telefono,
      );
      if (!mounted) return;
      setState(() {
        _otpHint = result.message;
        _codeStep = true;
      });
    } catch (e) {
      _snack('No se pudo enviar el código: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verifyCode() async {
    final telefono = normalizeAgendaPhoneDigits(_telCtrl.text);
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _otpError = 'Ingresá el código de WhatsApp.');
      return;
    }

    setState(() {
      _submitting = true;
      _otpError = null;
    });
    try {
      final api = ref.read(agendaApiServiceProvider);
      final result = await api.verifyPublicPhoneCode(
        businessId: widget.business.id,
        telefono: telefono,
        code: code,
      );
      final session = StoredPublicClientSession.fresh(
        token: result.clientSessionToken,
        businessId: widget.business.id,
        phone: telefono,
        needsName: result.client.needsName,
        nombre: result.client.needsName ? null : result.client.nombre,
      );
      await ref.read(publicClientSessionStorageProvider).save(widget.slug, session);
      ref.invalidate(publicClientSessionProvider(widget.slug));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _snack('Código inválido o vencido: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Verificá tu WhatsApp',
                style: t.textStyle(size: 20, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _codeStep
                    ? (_otpHint ?? 'Ingresá el código de 6 dígitos que recibiste.')
                    : 'Para guardar favoritos necesitamos validar tu número.',
                style: t.textStyle(size: 14, color: t.textSub),
              ),
              const SizedBox(height: 20),
              if (!_codeStep) ...[
                AgendaPhoneField(
                  controller: _telCtrl,
                  required: true,
                  useKonectaTokens: false,
                  helperText: 'Código de país + número móvil',
                ),
              ] else ...[
                if (_telCtrl.text.isNotEmpty)
                  Text(
                    'Enviado a ${_telCtrl.text}',
                    style: t.textStyle(size: 13, weight: FontWeight.w600),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Código de verificación',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_otpError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _otpError!,
                    style: t.textStyle(size: 13, color: Colors.red.shade700),
                  ),
                ],
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: t.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submitting
                      ? null
                      : (_codeStep ? _verifyCode : _sendOtp),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _codeStep ? 'Verificar código' : 'Enviar código por WhatsApp',
                          style: t.textStyle(
                            size: 15,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancelar', style: t.textStyle(color: t.textSub)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
