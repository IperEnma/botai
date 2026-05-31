import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/bot_provider.dart';
import '../../models/bot.dart';
import '../../core/theme.dart';
import '../menus/menus_screen.dart';
import '../knowledge/knowledge_screen.dart';
import '../bots/widgets/bot_linked_branches_card.dart';
import '../bots/widgets/whatsapp_access_token_help.dart';
import '../bots/widgets/whatsapp_webhook_setup.dart';

class BotDetailScreen extends ConsumerStatefulWidget {
  final String botId;

  const BotDetailScreen({super.key, required this.botId});

  @override
  ConsumerState<BotDetailScreen> createState() => _BotDetailScreenState();
}

class _BotDetailScreenState extends ConsumerState<BotDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final botsState = ref.watch(botsProvider);
    final bot = botsState.bots.where((b) => b.id == widget.botId).firstOrNull;

    if (bot == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/bots'),
          ),
          title: const Text('Bot no encontrado'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Este bot no existe o fue eliminado'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/bots'),
                child: const Text('Volver al Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/bots'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bot.name, style: const TextStyle(fontSize: 18)),
                Text(
                  bot.tierLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _StatusChip(label: 'FAQ', enabled: bot.faqEnabled),
          const SizedBox(width: 4),
          _StatusChip(label: 'IA', enabled: bot.aiEnabled),
          const SizedBox(width: 4),
          _StatusChip(label: 'CRM', enabled: bot.actionsEnabled),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Configuración'),
            Tab(icon: Icon(Icons.menu_book), text: 'Menús'),
            Tab(icon: Icon(Icons.psychology), text: 'Knowledge'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BotConfigContent(bot: bot),
          MenusContent(botId: widget.botId, tenantId: bot.tenantId),
          KnowledgeContent(botId: widget.botId, tenantId: bot.tenantId),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool enabled;

  const _StatusChip({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? AppTheme.successColor.withValues(alpha: 0.1) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: enabled ? AppTheme.successColor : Colors.grey[500],
        ),
      ),
    );
  }
}

// ============ CONFIG TAB ============

class BotConfigContent extends ConsumerStatefulWidget {
  final Bot bot;

  const BotConfigContent({super.key, required this.bot});

  @override
  ConsumerState<BotConfigContent> createState() => _BotConfigContentState();
}

class _BotConfigContentState extends ConsumerState<BotConfigContent> {
  late TextEditingController _phoneIdController;
  late TextEditingController _accessTokenController;
  late bool _faqEnabled;
  late bool _aiEnabled;
  late bool _actionsEnabled;
  bool _isLoading = false;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _phoneIdController = TextEditingController(text: widget.bot.whatsappPhoneNumberId ?? '');
    _accessTokenController = TextEditingController();
    _faqEnabled = widget.bot.faqEnabled;
    _aiEnabled = widget.bot.aiEnabled;
    _actionsEnabled = widget.bot.actionsEnabled;
  }

  @override
  void dispose() {
    _phoneIdController.dispose();
    _accessTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BotLinkedBranchesCard(bot: widget.bot),
          const SizedBox(height: 24),
          // WhatsApp Config
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Configuración de WhatsApp',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _WhatsAppTutorialCard(),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneIdController,
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
                      const Spacer(),
                      const WhatsAppAccessTokenHelpButton(compact: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _accessTokenController,
                    decoration: InputDecoration(
                      hintText: widget.bot.whatsappAccessTokenConfigured
                          ? 'Token guardado — dejá vacío para no cambiarlo'
                          : 'EAAxxxxxxx...',
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
                    obscureText: _obscureToken,
                  ),
                  if (widget.bot.whatsappAccessTokenConfigured)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Access Token configurado (cifrado en el servidor).',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  const SizedBox(height: 20),
                  WhatsAppWebhookSetup(botId: widget.bot.id),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Feature Flags
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.toggle_on, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Capas Activas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Capa 1: FAQ / Menús'),
                    subtitle: const Text('Respuestas predefinidas y menús interactivos'),
                    value: _faqEnabled,
                    onChanged: (v) => setState(() => _faqEnabled = v),
                    secondary: const Icon(Icons.list_alt),
                  ),
                  SwitchListTile(
                    title: const Text('Capa 2: IA Híbrida'),
                    subtitle: const Text('Respuestas con IA usando tu base de conocimiento'),
                    value: _aiEnabled,
                    onChanged: (v) => setState(() => _aiEnabled = v),
                    secondary: const Icon(Icons.psychology),
                  ),
                  SwitchListTile(
                    title: const Text('Capa 3: CRM / Acciones'),
                    subtitle: const Text('Crear leads, agendar citas, etc. (Próximamente)'),
                    value: _actionsEnabled,
                    onChanged: (v) => setState(() => _actionsEnabled = v),
                    secondary: const Icon(Icons.integration_instructions),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveConfig,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Guardando...' : 'Guardar Configuración'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);

    final newAccessToken = _accessTokenController.text.trim();
    final updatedBot = widget.bot.copyWith(
      whatsappPhoneNumberId: _phoneIdController.text.trim().isEmpty ? null : _phoneIdController.text.trim(),
      faqEnabled: _faqEnabled,
      aiEnabled: _aiEnabled,
      actionsEnabled: _actionsEnabled,
      whatsappAccessTokenConfigured: widget.bot.whatsappAccessTokenConfigured ||
          newAccessToken.isNotEmpty,
    );

    await ref.read(botsProvider.notifier).updateBot(
          updatedBot,
          whatsappAccessTokenPlain:
              newAccessToken.isEmpty ? null : newAccessToken,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
    }
  }
}

// ============ WHATSAPP TUTORIAL & WEBHOOK ============

class _WhatsAppTutorialCard extends StatelessWidget {
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
                '¿Cómo obtener estas credenciales?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1. Ve a developers.facebook.com\n'
            '2. Crea una app de tipo "Business"\n'
            '3. Agrega el producto "WhatsApp"\n'
            '4. En WhatsApp > API Setup encontrarás:\n'
            '   • Phone number ID\n'
            '   • Access Token (temporal o permanente)\n'
            '5. Después de crear el bot, copiá URL y Verify Token desde Configuración',
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

// Horario y Servicios se gestionan desde AGENDA (panel del negocio), no desde la configuración del bot.

// ============ MENUS TAB ============

class MenusContent extends StatelessWidget {
  final String botId;
  final String tenantId;

  const MenusContent({super.key, required this.botId, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return MenusScreen(botId: botId, tenantId: tenantId, embedded: true);
  }
}

// ============ KNOWLEDGE TAB ============

class KnowledgeContent extends StatelessWidget {
  final String botId;
  final String tenantId;

  const KnowledgeContent({super.key, required this.botId, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return KnowledgeScreen(botId: botId, tenantId: tenantId, embedded: true);
  }
}
