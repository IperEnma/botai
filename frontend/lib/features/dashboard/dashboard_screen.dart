import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/agenda/business.dart';
import '../../models/bot.dart';
import '../../core/theme.dart';
import '../../providers/agenda/tenant/businesses_provider.dart';
import '../../providers/agenda/tenant_admin_resolved_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bot_provider.dart';
import '../../services/agenda_api_exception.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(botsProvider.notifier).loadBots());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final botsState = ref.watch(botsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(botsProvider.notifier).loadBots(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeCard(user: authState.user),
            const SizedBox(height: 24),
            const Text(
              'Tus Bots',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (botsState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (botsState.bots.isEmpty)
              _EmptyBotsCard(onCreateBot: () => _showCreateBotDialog(context))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: botsState.bots.length + 1,
                itemBuilder: (context, index) {
                  if (index == botsState.bots.length) {
                    return _AddBotCard(onTap: () => _showCreateBotDialog(context));
                  }
                  return _BotCard(
                    bot: botsState.bots[index],
                    onTap: () {
                      ref.read(selectedBotProvider.notifier).state =
                          botsState.bots[index];
                      context.go('/bots/${botsState.bots[index].id}');
                    },
                  );
                },
              ),
            const SizedBox(height: 32),
            const Text(
              'Guía Rápida',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _QuickGuideSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBotDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Bot'),
      ),
    );
  }

  void _showCreateBotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateBotDialog(),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final dynamic user;

  const _WelcomeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, ${user?.name?.split(' ').first ?? 'Usuario'}! 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenido a BotAI. Configura y gestiona tus chatbots.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.smart_toy, size: 64, color: Colors.white24),
        ],
      ),
    );
  }
}

class _EmptyBotsCard extends StatelessWidget {
  final VoidCallback onCreateBot;

  const _EmptyBotsCard({required this.onCreateBot});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.smart_toy_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No tienes bots configurados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer bot para empezar',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateBot,
              icon: const Icon(Icons.add),
              label: const Text('Crear Bot'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotCard extends StatelessWidget {
  final Bot bot;
  final VoidCallback onTap;

  const _BotCard({required this.bot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.smart_toy, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bot.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          bot.tierLabel,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _StatusChip(
                    label: 'FAQ',
                    enabled: bot.faqEnabled,
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'IA',
                    enabled: bot.aiEnabled,
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'CRM',
                    enabled: bot.actionsEnabled,
                  ),
                ],
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? AppTheme.successColor.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: enabled ? AppTheme.successColor : Colors.grey[500],
        ),
      ),
    );
  }
}

class _AddBotCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddBotCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Agregar Bot',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickGuideSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GuideCard(
          icon: Icons.looks_one,
          title: 'Capa 1: FAQ / Menús',
          description:
              'Configura respuestas predefinidas y menús interactivos. Ideal para preguntas frecuentes.',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _GuideCard(
          icon: Icons.looks_two,
          title: 'Capa 2: IA Híbrida',
          description:
              'Agrega contexto para que la IA responda preguntas basadas en tu documentación (RAG).',
          color: Colors.purple,
        ),
        const SizedBox(height: 12),
        _GuideCard(
          icon: Icons.looks_3,
          title: 'Capa 3: CRM (Próximamente)',
          description:
              'Integración con CRM para agendar citas, crear leads y más acciones automatizadas.',
          color: Colors.orange,
          comingSoon: true,
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool comingSoon;

  const _GuideCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateBotDialog extends ConsumerStatefulWidget {
  const _CreateBotDialog();

  @override
  ConsumerState<_CreateBotDialog> createState() => _CreateBotDialogState();
}

class _CreateBotDialogState extends ConsumerState<_CreateBotDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  BotTier _selectedTier = BotTier.tier1;
  bool _isLoading = false;
  final Set<String> _selectedBusinessIds = {};

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _mapTenantError(Object e) {
    if (e is TenantAdminResolveException) {
      return 'Iniciá sesión para vincular el bot con tus sucursales de Agenda.';
    }
    if (e is AgendaApiException) {
      if (e.status == 404) {
        return 'No encontramos tu espacio Agenda. Registrate o completá el alta en Agenda antes de crear el bot.';
      }
      return e.message;
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tenantAsync = ref.watch(tenantAdminResolvedProvider);

    return tenantAsync.when(
      loading: () => AlertDialog(
        title: const Text('Crear Nuevo Bot'),
        content: const SizedBox(
          width: 320,
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
      error: (e, _) => AlertDialog(
        title: const Text('Crear Nuevo Bot'),
        content: SingleChildScrollView(child: Text(_mapTenantError(e))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/agenda/panel');
            },
            child: const Text('Ir a Agenda'),
          ),
        ],
      ),
      data: (tenantCtx) => _buildFormDialog(context, tenantCtx.tenantId),
    );
  }

  Widget _buildFormDialog(BuildContext context, String agendaTenantId) {
    final bizState = ref.watch(businessesProvider(agendaTenantId));
    final maxH = MediaQuery.of(context).size.height * 0.65;

    return AlertDialog(
      title: const Text('Crear Nuevo Bot'),
      content: SizedBox(
        width: 400,
        height: maxH,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Bot',
                      hintText: 'Ej: Mi Clínica Bot',
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      hintText: 'Ej: Bot para atención al cliente',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<BotTier>(
                    value: _selectedTier,
                    decoration: const InputDecoration(labelText: 'Capa'),
                    items: BotTier.values.map((tier) {
                      return DropdownMenuItem(
                        value: tier,
                        child: Text(_getTierLabel(tier)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedTier = v!),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sucursales (Agenda) · obligatorio',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'El bot atiende solo las sucursales que marques (mínimo 1). Mismo tenant que Agenda.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Obligatorio: cada bot debe estar vinculado a al menos una sucursal de Agenda. '
                            'Podés elegir una o marcar todas.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (bizState.items.length > 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedBusinessIds
                              ..clear()
                              ..addAll(
                                bizState.items
                                    .where((b) => b.activo)
                                    .map((b) => b.id),
                              );
                          });
                        },
                        child: const Text('Seleccionar todas las sucursales'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (bizState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (bizState.error != null)
                    Text(
                      bizState.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    )
                  else if (bizState.items.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No tenés sucursales cargadas. Creá al menos una en Agenda.',
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.go('/agenda/panel');
                          },
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('Ir a mis negocios'),
                        ),
                      ],
                    )
                  else
                    ..._branchTiles(bizState.items),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _createBot(agendaTenantId),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }

  List<Widget> _branchTiles(List<Business> items) {
    return [
      for (final b in items)
        CheckboxListTile(
          dense: true,
          value: _selectedBusinessIds.contains(b.id),
          onChanged: b.activo
              ? (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedBusinessIds.add(b.id);
                    } else {
                      _selectedBusinessIds.remove(b.id);
                    }
                  });
                }
              : null,
          title: Text(b.nombre),
          subtitle: b.activo
              ? (b.botId != null
                  ? Text('Ya vinculada a bot #${b.botId}', style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                  : null)
              : const Text('Inactiva — no disponible'),
        ),
    ];
  }

  String _getTierLabel(BotTier tier) {
    switch (tier) {
      case BotTier.tier1:
        return 'Capa 1 - FAQ';
      case BotTier.tier2:
        return 'Capa 2 - IA Híbrida';
      case BotTier.tier3:
        return 'Capa 3 - IA + CRM';
    }
  }

  Future<void> _createBot(String agendaTenantId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusinessIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elegí al menos una sucursal para este bot.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final bot = Bot(
      id: '',
      tenantId: agendaTenantId,
      name: _nameController.text,
      description: _descController.text.isEmpty ? null : _descController.text,
      tier: _selectedTier,
      faqEnabled: true,
      aiEnabled: _selectedTier != BotTier.tier1,
      actionsEnabled: _selectedTier == BotTier.tier3,
      linkedAgendaBusinessIds: _selectedBusinessIds.toList(),
      createdAt: DateTime.now(),
    );

    final created = await ref.read(botsProvider.notifier).createBot(bot);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bot creado exitosamente')),
        );
      } else {
        final err = ref.read(botsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'No se pudo crear el bot')),
        );
      }
    }
  }
}
