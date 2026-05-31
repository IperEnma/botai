import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/whatsapp_webhook_setup.dart';
import '../../../providers/bot_provider.dart';
import '../../agenda/register/konecta_tokens.dart';

const _verifyTokenDeliveredKeyPrefix = 'wa_verify_delivered_';

/// URL del webhook + verify token (copia al portapapeles; no se muestra en pantalla).
class WhatsAppWebhookSetup extends ConsumerStatefulWidget {
  const WhatsAppWebhookSetup({
    super.key,
    required this.botId,
    this.compact = false,
    this.style = WhatsAppWebhookSetupStyle.material,
  });

  final String botId;
  final bool compact;
  final WhatsAppWebhookSetupStyle style;

  @override
  ConsumerState<WhatsAppWebhookSetup> createState() =>
      _WhatsAppWebhookSetupState();
}

enum WhatsAppWebhookSetupStyle { material, konecta }

class _WhatsAppWebhookSetupState extends ConsumerState<WhatsAppWebhookSetup> {
  WhatsAppWebhookSetupInfo? _info;
  Object? _error;
  bool _verifyTokenDelivered = false;

  @override
  void initState() {
    super.initState();
    _loadDeliveredFlag();
    _load();
  }

  @override
  void didUpdateWidget(covariant WhatsAppWebhookSetup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.botId != widget.botId) {
      _loadDeliveredFlag();
      _load();
    }
  }

  Future<void> _loadDeliveredFlag() async {
    if (widget.botId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _verifyTokenDelivered =
          prefs.getBool('$_verifyTokenDeliveredKeyPrefix${widget.botId}') ??
              false;
    });
  }

  Future<void> _load() async {
    if (widget.botId.isEmpty) return;
    setState(() {
      _info = null;
      _error = null;
    });
    try {
      final info = await ref
          .read(botsProvider.notifier)
          .fetchWhatsAppWebhookSetup(widget.botId);
      if (mounted) setState(() => _info = info);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _copyVerifyToken({required bool markDelivered}) async {
    final token = _info?.verifyToken ?? '';
    if (token.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: token));

    if (markDelivered) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        '$_verifyTokenDeliveredKeyPrefix${widget.botId}',
        true,
      );
      if (mounted) setState(() => _verifyTokenDelivered = true);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          markDelivered
              ? 'Verify token copiado. Pegalo en Meta › Webhook (no se guarda en pantalla).'
              : 'Verify token copiado de nuevo.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(
        'No se pudo cargar la config del webhook.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 13,
        ),
      );
    }
    if (_info == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return widget.style == WhatsAppWebhookSetupStyle.konecta
        ? _KonectaBody(
            info: _info!,
            compact: widget.compact,
            verifyTokenDelivered: _verifyTokenDelivered,
            onCopyVerifyToken: _copyVerifyToken,
          )
        : _MaterialBody(
            info: _info!,
            compact: widget.compact,
            verifyTokenDelivered: _verifyTokenDelivered,
            onCopyVerifyToken: _copyVerifyToken,
          );
  }
}

/// Mensaje en el wizard de creación (aún no hay botId).
class WhatsAppWebhookSetupPending extends StatelessWidget {
  const WhatsAppWebhookSetupPending({
    super.key,
    this.style = WhatsAppWebhookSetupStyle.material,
  });

  final WhatsAppWebhookSetupStyle style;

  @override
  Widget build(BuildContext context) {
    if (style == WhatsAppWebhookSetupStyle.konecta) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KTokens.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KTokens.border),
        ),
        child: Text(
          'Al crear el bot, en Configuración vas a copiar la URL del webhook y el verify token '
          '(se genera solo y se copia al portapapeles; no queda visible en pantalla).',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: KTokens.inkMuted,
            height: 1.5,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Al crear el bot, en Configuración copiás la URL y el verify token en Meta › WhatsApp › Webhook. '
        'El token se copia al portapapeles y no se muestra en pantalla.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
      ),
    );
  }
}

class _MaterialBody extends StatelessWidget {
  const _MaterialBody({
    required this.info,
    required this.compact,
    required this.verifyTokenDelivered,
    required this.onCopyVerifyToken,
  });

  final WhatsAppWebhookSetupInfo info;
  final bool compact;
  final bool verifyTokenDelivered;
  final Future<void> Function({required bool markDelivered}) onCopyVerifyToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            'Webhook en Meta',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            info.hint ??
                'Copiá la URL en Meta › WhatsApp › Configuration › Webhook. '
                'El verify token se copia con el botón (no se muestra acá).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
        ],
        _CopyField(label: 'URL del Webhook', value: info.webhookUrl),
        const SizedBox(height: 12),
        _VerifyTokenCopySection(
          delivered: verifyTokenDelivered,
          onCopy: onCopyVerifyToken,
          style: WhatsAppWebhookSetupStyle.material,
        ),
      ],
    );
  }
}

class _KonectaBody extends StatelessWidget {
  const _KonectaBody({
    required this.info,
    required this.compact,
    required this.verifyTokenDelivered,
    required this.onCopyVerifyToken,
  });

  final WhatsAppWebhookSetupInfo info;
  final bool compact;
  final bool verifyTokenDelivered;
  final Future<void> Function({required bool markDelivered}) onCopyVerifyToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            'WEBHOOK EN META',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: KTokens.inkSoft,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            info.hint ??
                'URL en Meta › Webhook. Verify token: botón copiar (no visible en pantalla).',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: KTokens.inkMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
        _KonectaCopyField(label: 'URL DEL WEBHOOK', value: info.webhookUrl),
        const SizedBox(height: 16),
        _VerifyTokenCopySection(
          delivered: verifyTokenDelivered,
          onCopy: onCopyVerifyToken,
          style: WhatsAppWebhookSetupStyle.konecta,
        ),
      ],
    );
  }
}

class _VerifyTokenCopySection extends StatelessWidget {
  const _VerifyTokenCopySection({
    required this.delivered,
    required this.onCopy,
    required this.style,
  });

  final bool delivered;
  final Future<void> Function({required bool markDelivered}) onCopy;
  final WhatsAppWebhookSetupStyle style;

  @override
  Widget build(BuildContext context) {
    if (style == WhatsAppWebhookSetupStyle.konecta) {
      return _konecta(context);
    }
    return _material(context);
  }

  Widget _material(BuildContext context) {
    if (delivered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 18, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verify token copiado. Pegalo en Meta; no se muestra de nuevo acá.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade900,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => onCopy(markDelivered: false),
                child: const Text('Copiar otra vez'),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Token',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          'Se genera solo para este bot. No se muestra en pantalla: se copia al portapapeles.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
                height: 1.35,
              ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => onCopy(markDelivered: true),
          icon: const Icon(Icons.content_copy, size: 18),
          label: const Text('Copiar verify token'),
        ),
      ],
    );
  }

  Widget _konecta(BuildContext context) {
    if (delivered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KTokens.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'VERIFY TOKEN COPIADO — pegalo en Meta; no queda visible acá.',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: KTokens.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => onCopy(markDelivered: false),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Copiar otra vez',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: KTokens.inkSoft,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VERIFY TOKEN',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: KTokens.inkSoft,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Generado para este bot. Copialo con el botón; no se muestra en pantalla.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: KTokens.inkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => onCopy(markDelivered: true),
          icon: const Icon(Icons.content_copy, size: 16),
          label: Text(
            'COPIAR VERIFY TOKEN',
            style: GoogleFonts.jetBrainsMono(fontSize: 11, letterSpacing: 0.6),
          ),
        ),
      ],
    );
  }
}

class _CopyField extends StatelessWidget {
  const _CopyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copiar',
                onPressed: () => _copy(context, value, label),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KonectaCopyField extends StatelessWidget {
  const _KonectaCopyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: KTokens.inkSoft,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: KTokens.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: KTokens.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: KTokens.ink,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: KTokens.inkSoft),
                splashRadius: 16,
                tooltip: 'Copiar',
                onPressed: () => _copy(context, value, label),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _copy(BuildContext context, String value, String label) {
  Clipboard.setData(ClipboardData(text: value));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label copiado'),
      duration: const Duration(seconds: 2),
    ),
  );
}
