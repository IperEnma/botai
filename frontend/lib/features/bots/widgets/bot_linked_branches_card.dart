import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/agenda/business.dart';
import '../../../models/bot.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import 'bot_branch_utils.dart';

/// Muestra y edita qué sucursales atiende un bot (mínimo 1; puede ser todas).
class BotLinkedBranchesCard extends ConsumerStatefulWidget {
  const BotLinkedBranchesCard({super.key, required this.bot});

  final Bot bot;

  @override
  ConsumerState<BotLinkedBranchesCard> createState() =>
      _BotLinkedBranchesCardState();
}

class _BotLinkedBranchesCardState extends ConsumerState<BotLinkedBranchesCard> {
  late Set<String> _selected;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = {};
  }

  void _syncFromBusinesses(List<Business> items) {
    if (_dirty) return;
    final botId = int.tryParse(widget.bot.id);
    if (botId == null) return;
    final linked = items.where((b) => b.botId == botId).map((b) => b.id);
    if (linked.isNotEmpty) {
      _selected = linked.toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bizState = ref.watch(businessesProvider(widget.bot.tenantId));
    final active = bizState.items.where((b) => b.activo).toList();

    if (!bizState.isLoading && bizState.items.isNotEmpty) {
      _syncFromBusinesses(bizState.items);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_outlined, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sucursales que atiende',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Obligatorio: cada bot debe estar vinculado a al menos una sucursal. '
              'Podés elegir una sola o todas las de tu espacio Agenda.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.45),
            ),
            const SizedBox(height: 16),
            if (bizState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (active.isEmpty)
              const Text('No tenés sucursales activas en Agenda.')
            else ...[
              if (active.length > 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _dirty = true;
                      _selected = active.map((b) => b.id).toSet();
                    }),
                    child: const Text('Seleccionar todas'),
                  ),
                ),
              for (final b in active) ...[
                Builder(
                  builder: (context) {
                    final botId = int.tryParse(widget.bot.id);
                    final otherBot = b.botId != null &&
                        botId != null &&
                        b.botId != botId;
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _selected.contains(b.id),
                      onChanged: (checked) => setState(() {
                        _dirty = true;
                        if (checked == true) {
                          _selected.add(b.id);
                        } else {
                          _selected.remove(b.id);
                        }
                      }),
                      title: Text(b.nombre),
                      subtitle: otherBot
                          ? Text(
                              'Actualmente en bot #${b.botId} — al guardar pasa a este bot',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange[800]),
                            )
                          : null,
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving || _selected.isEmpty ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: Text(_saving ? 'Guardando…' : 'Guardar sucursales'),
                ),
              ),
              if (_selected.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Elegí al menos una sucursal.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Atiende: ${formatBranchSummary(active.where((b) => _selected.contains(b.id)).map((b) => b.nombre).toList())}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    final botId = int.tryParse(widget.bot.id);
    if (botId == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(agendaApiServiceProvider).replaceBotLinkedBusinesses(
            botId: botId,
            businessIds: _selected.toList(),
          );
      ref.invalidate(businessesProvider(widget.bot.tenantId));
      if (mounted) {
        setState(() {
          _saving = false;
          _dirty = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sucursales actualizadas')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    }
  }
}
