import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/knowledge.dart';
import '../../providers/auth_provider.dart';

class KnowledgeScreen extends ConsumerStatefulWidget {
  final String botId;
  final String? tenantId;
  final bool embedded;

  const KnowledgeScreen({super.key, required this.botId, this.tenantId, this.embedded = false});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  List<KnowledgeChunk> _chunks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.tenantId != null && widget.tenantId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadKnowledge());
    } else {
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(KnowledgeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tenantId != null && widget.tenantId != oldWidget.tenantId) {
      _loadKnowledge();
    }
  }

  Future<void> _loadKnowledge() async {
    final tenantId = widget.tenantId;
    if (tenantId == null || tenantId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final list = await api.getKnowledge(tenantId);
      if (mounted) {
        setState(() {
          _chunks = list;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _saveChunk(KnowledgeChunk chunk, {bool isNew = false}) async {
    final tenantId = widget.tenantId ?? chunk.tenantId;
    if (tenantId.isEmpty) return;
    final chunkWithTenant = chunk.copyWith(tenantId: tenantId);
    try {
      final api = ref.read(apiServiceProvider);
      if (isNew || chunk.id == null || chunk.id!.isEmpty) {
        final saved = await api.createKnowledge(chunkWithTenant);
        if (mounted) setState(() => _chunks = [..._chunks, saved]);
      } else {
        final saved = await api.updateKnowledge(chunkWithTenant);
        if (mounted) {
          setState(() {
            final i = _chunks.indexWhere((c) => c.id == saved.id);
            if (i >= 0) _chunks = [..._chunks]..[i] = saved;
          });
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fragmento guardado'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error al cargar conocimiento: $_error', style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadKnowledge, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (widget.tenantId == null || widget.tenantId!.isEmpty) {
      return const Center(child: Text('Selecciona un bot para gestionar su base de conocimiento'));
    }

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(),
          const SizedBox(height: 24),
          Card(
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
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.psychology, color: Colors.purple),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fragmentos de Conocimiento',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'La IA usará esta información para responder preguntas',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showChunkDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _chunks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final chunk = _chunks[index];
                      return _KnowledgeChunkCard(
                        chunk: chunk,
                        onEdit: () => _showChunkDialog(chunk: chunk, index: index),
                        onDelete: () => _confirmDelete(index),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _TipsCard(),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Base de Conocimiento'),
        actions: [
          TextButton.icon(
            onPressed: _showImportDialog,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importar'),
          ),
        ],
      ),
      body: content,
    );
  }

  void _showChunkDialog({KnowledgeChunk? chunk, int? index}) {
    final topicController = TextEditingController(text: chunk?.topic ?? '');
    final contentController = TextEditingController(text: chunk?.content ?? '');
    final keywordsController = TextEditingController(text: chunk?.keywords ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chunk != null ? 'Editar Fragmento' : 'Nuevo Fragmento'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: topicController,
                decoration: const InputDecoration(
                  labelText: 'Tema / Título',
                  hintText: 'Ej: Horarios, Precios, Servicios',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  hintText: 'Información detallada que la IA puede usar...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keywordsController,
                decoration: const InputDecoration(
                  labelText: 'Palabras clave (separadas por coma)',
                  hintText: 'horario, abierto, cierra, días',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newChunk = KnowledgeChunk(
                id: chunk?.id,
                tenantId: widget.tenantId ?? chunk?.tenantId ?? '',
                topic: topicController.text,
                content: contentController.text,
                keywords: keywordsController.text.isEmpty ? null : keywordsController.text,
              );
              Navigator.pop(context);
              _saveChunk(newChunk, isNew: chunk == null);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int index) {
    final chunk = _chunks[index];
    final tenantId = widget.tenantId;
    if (tenantId == null || tenantId.isEmpty || chunk.id == null || chunk.id!.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar fragmento'),
        content: Text('¿Seguro que quieres eliminar "${chunk.topic}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(apiServiceProvider).deleteKnowledge(tenantId, chunk.id!);
                if (mounted) {
                  setState(() => _chunks = _chunks.where((c) => c.id != chunk.id).toList());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fragmento eliminado')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar Conocimiento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Puedes importar información desde diferentes fuentes:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _ImportOption(
              icon: Icons.description,
              title: 'Archivo de texto (.txt)',
              subtitle: 'Sube un archivo con información',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _ImportOption(
              icon: Icons.table_chart,
              title: 'CSV / Excel',
              subtitle: 'Importa desde una hoja de cálculo',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _ImportOption(
              icon: Icons.language,
              title: 'Página web (URL)',
              subtitle: 'Extrae contenido de una URL',
              onTap: () {},
              comingSoon: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Capa 2: IA con RAG',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agrega información que la IA usará para responder preguntas. '
                  'Cuanto más contexto agregues, mejores serán las respuestas.',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeChunkCard extends StatelessWidget {
  final KnowledgeChunk chunk;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KnowledgeChunkCard({
    required this.chunk,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  chunk.topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: onEdit,
                tooltip: 'Editar',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Eliminar',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            chunk.content,
            style: const TextStyle(height: 1.5),
          ),
          if (chunk.keywords != null && chunk.keywords!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: chunk.keywords!.split(',').map((k) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    k.trim(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Consejos para mejores respuestas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Tip(
              number: '1',
              text: 'Sé específico: incluye datos concretos como precios, horarios, direcciones.',
            ),
            _Tip(
              number: '2',
              text: 'Usa palabras clave relevantes que los usuarios podrían usar al preguntar.',
            ),
            _Tip(
              number: '3',
              text: 'Organiza la información en temas separados para mejor precisión.',
            ),
            _Tip(
              number: '4',
              text: 'Actualiza regularmente la información para mantenerla vigente.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String number;
  final String text;

  const _Tip({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ImportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool comingSoon;

  const _ImportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: comingSoon ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: comingSoon ? Colors.grey : AppTheme.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: comingSoon ? Colors.grey : null,
                        ),
                      ),
                      if (comingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Pronto',
                            style: TextStyle(fontSize: 10, color: Colors.orange[700]),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: comingSoon ? Colors.grey[300] : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
