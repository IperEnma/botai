import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../bots/widgets/whatsapp_access_token_help.dart';
import '../bots/widgets/whatsapp_webhook_setup.dart';

class BotConfigScreen extends ConsumerStatefulWidget {
  final String botId;

  const BotConfigScreen({super.key, required this.botId});

  @override
  ConsumerState<BotConfigScreen> createState() => _BotConfigScreenState();
}

class _BotConfigScreenState extends ConsumerState<BotConfigScreen> {
  final _phoneNumberIdController = TextEditingController();
  final _accessTokenController = TextEditingController();
  bool _obscureToken = true;

  @override
  void dispose() {
    _phoneNumberIdController.dispose();
    _accessTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Bot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Integración WhatsApp',
              subtitle: 'Conecta tu número de WhatsApp Business',
              icon: Icons.chat,
              iconColor: Colors.green,
              child: Column(
                children: [
                  _InfoCard(
                    title: '¿Cómo obtener estas credenciales?',
                    content: whatsAppMetaSetupTutorial(webhookVisibleBelow: true),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneNumberIdController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number ID',
                      hintText: 'Ej: 1234567890123456',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Access Token',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(width: 6),
                      const WhatsAppAccessTokenHelpButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _accessTokenController,
                    obscureText: _obscureToken,
                    decoration: InputDecoration(
                      hintText: 'EAAxxxxxxx...',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureToken ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscureToken = !_obscureToken);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  WhatsAppWebhookSetup(botId: widget.botId),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveWhatsAppConfig,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Configuración'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'Feature Flags',
              subtitle: 'Activa o desactiva funcionalidades',
              icon: Icons.toggle_on,
              iconColor: AppTheme.primaryColor,
              child: Column(
                children: [
                  _FeatureToggle(
                    title: 'FAQ / Menús (Capa 1)',
                    description: 'Respuestas predefinidas y menús interactivos',
                    value: true,
                    onChanged: (v) {},
                  ),
                  const Divider(),
                  _FeatureToggle(
                    title: 'IA Híbrida (Capa 2)',
                    description: 'Respuestas basadas en contexto con IA',
                    value: false,
                    onChanged: (v) {},
                  ),
                  const Divider(),
                  _FeatureToggle(
                    title: 'Acciones / CRM (Capa 3)',
                    description: 'Integración con CRM y acciones automatizadas',
                    value: false,
                    onChanged: (v) {},
                    comingSoon: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveWhatsAppConfig() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;

  const _InfoCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.blue[900],
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureToggle extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool comingSoon;

  const _FeatureToggle({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (comingSoon) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Próximamente',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: comingSoon ? null : onChanged,
          ),
        ],
      ),
    );
  }
}
