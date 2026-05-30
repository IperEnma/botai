import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/whatsapp_webhook_setup.dart';
import '../../../providers/bot_provider.dart';
import '../../agenda/register/konecta_tokens.dart';

/// URL y verify token del bot (generados en backend; copiar en Meta).
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WhatsAppWebhookSetup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.botId != widget.botId) {
      _load();
    }
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
        ? _KonectaBody(info: _info!, compact: widget.compact)
        : _MaterialBody(info: _info!, compact: widget.compact);
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
          'Al crear el bot verás URL y Verify Token en Configuración para pegarlos en Meta › WhatsApp › Webhook. '
          'Se generan solos (no hace falta inventarlos ni guardarlos).',
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
        'Al crear el bot verás URL y Verify Token en Configuración para copiarlos en Meta › WhatsApp › Webhook.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
      ),
    );
  }
}

class _MaterialBody extends StatelessWidget {
  const _MaterialBody({required this.info, required this.compact});

  final WhatsAppWebhookSetupInfo info;
  final bool compact;

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
                'Copiá estos valores en Meta › WhatsApp › Configuration › Webhook.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
        ],
        _CopyField(label: 'URL del Webhook', value: info.webhookUrl),
        const SizedBox(height: 12),
        _CopyField(label: 'Verify Token (de este bot)', value: info.verifyToken),
      ],
    );
  }
}

class _KonectaBody extends StatelessWidget {
  const _KonectaBody({required this.info, required this.compact});

  final WhatsAppWebhookSetupInfo info;
  final bool compact;

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
                'Copiá URL y Verify Token en Meta › WhatsApp › Configuration › Webhook.',
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
        _KonectaCopyField(
          label: 'VERIFY TOKEN (DE ESTE BOT)',
          value: info.verifyToken,
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
