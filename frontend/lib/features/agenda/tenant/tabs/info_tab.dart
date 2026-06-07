import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/agenda_search_tag.dart';
import '../../../../models/agenda/business.dart';
import '../../../../providers/agenda/public/public_categories_provider.dart';
import '../../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';
import '../widgets/business_form_dialog.dart';
import '../widgets/category_multi_select_dialog.dart';

class InfoTab extends ConsumerStatefulWidget {
  const InfoTab({
    super.key,
    required this.tenantId,
    required this.business,
    this.scrollable = true,
  });

  final String tenantId;
  final Business business;
  final bool scrollable;

  @override
  ConsumerState<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends ConsumerState<InfoTab> {
  late TextEditingController _instagramCtrl;
  late TextEditingController _tiktokCtrl;
  late TextEditingController _facebookCtrl;
  bool _socialChanged = false;
  bool _isSavingSocial = false;

  @override
  void initState() {
    super.initState();
    _instagramCtrl = TextEditingController(text: widget.business.instagramUrl ?? '');
    _tiktokCtrl = TextEditingController(text: widget.business.tiktokUrl ?? '');
    _facebookCtrl = TextEditingController(text: widget.business.facebookUrl ?? '');
  }

  @override
  void dispose() {
    _instagramCtrl.dispose();
    _tiktokCtrl.dispose();
    _facebookCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    final categoriesAsync = ref.watch(publicCategoriesProvider);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // ── Información básica ─────────────────────────────────────────
          _SectionHeader('Información básica'),
          const SizedBox(height: 12),
          _InfoRow(label: 'Nombre', value: business.nombre),
          if (business.descripcion != null)
            _InfoRow(label: 'Descripción', value: business.descripcion!),
          _InfoRow(
            label: 'Rubro / etiquetas del perfil',
            value: business.profileTagLabels.isEmpty
                ? 'Sin etiquetas'
                : business.profileTagLabels.join(', '),
          ),
          _InfoRow(label: 'Activo', value: business.activo ? 'Sí' : 'No'),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Editar información'),
            onPressed: () async {
              final result = await showDialog<BusinessFormResult>(
                context: context,
                builder: (_) => BusinessFormDialog(initial: business),
              );
              if (result == null || !context.mounted) return;
              try {
                await ref
                    .read(businessesProvider(widget.tenantId).notifier)
                    .update(
                      businessId: business.id,
                      nombre: result.nombre,
                      descripcion: result.descripcion,
                      searchTags: mergeAgendaSearchTags(
                        existing: business.searchTags,
                        profileLabels: result.profileLabels,
                      ),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Negocio actualizado')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
          ),

          const SizedBox(height: 36),
          const Divider(),
          const SizedBox(height: 24),

          // ── Categorías ────────────────────────────────────────────────
          _SectionHeader('Categorías'),
          const SizedBox(height: 12),
          categoriesAsync.when(
            loading: () => const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => AgendaErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(publicCategoriesProvider),
            ),
            data: (allCategories) {
              final associated = business.categorias;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (associated.isEmpty)
                    Text(
                      'Sin categorías asociadas.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: associated
                          .map((slug) => Chip(label: Text(slug)))
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar categorías'),
                    onPressed: () async {
                      final selectedIds = await CategoryMultiSelectDialog.show(
                        context,
                        allCategories: allCategories,
                        selectedSlugs: associated,
                      );
                      if (selectedIds == null || !context.mounted) return;
                      try {
                        await ref
                            .read(businessesProvider(widget.tenantId).notifier)
                            .associateCategories(
                              businessId: business.id,
                              categoryIds: selectedIds,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Categorías actualizadas')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 36),
          const Divider(),
          const SizedBox(height: 24),

          // ── Redes sociales ────────────────────────────────────────────
          _SectionHeader('Redes sociales'),
          const SizedBox(height: 16),
          _SocialField(
            controller: _instagramCtrl,
            label: 'Instagram',
            hint: 'https://instagram.com/tu_negocio',
            icon: Icons.camera_alt_outlined,
            color: const Color(0xFFE1306C),
            onChanged: (_) => setState(() => _socialChanged = true),
          ),
          const SizedBox(height: 12),
          _SocialField(
            controller: _tiktokCtrl,
            label: 'TikTok',
            hint: 'https://tiktok.com/@tu_negocio',
            icon: Icons.music_note_outlined,
            color: Colors.black87,
            onChanged: (_) => setState(() => _socialChanged = true),
          ),
          const SizedBox(height: 12),
          _SocialField(
            controller: _facebookCtrl,
            label: 'Facebook',
            hint: 'https://facebook.com/tu_negocio',
            icon: Icons.facebook_outlined,
            color: const Color(0xFF1877F2),
            onChanged: (_) => setState(() => _socialChanged = true),
          ),
          const SizedBox(height: 20),
          if (_socialChanged)
            FilledButton.icon(
              icon: _isSavingSocial
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_isSavingSocial ? 'Guardando…' : 'Guardar redes'),
              onPressed: _isSavingSocial ? null : _saveSocial,
            ),
      ],
    );

    return widget.scrollable
        ? SingleChildScrollView(padding: const EdgeInsets.all(24), child: content)
        : Padding(padding: const EdgeInsets.all(24), child: content);
  }

  Future<void> _saveSocial() async {
    setState(() => _isSavingSocial = true);
    try {
      final b = widget.business;
      await ref.read(businessesProvider(widget.tenantId).notifier).update(
            businessId: b.id,
            nombre: b.nombre,
            descripcion: b.descripcion,
            searchTags: b.searchTags,
            logoUrl: b.logoUrl,
            colorPrimario: b.colorPrimario,
            instagramUrl: _instagramCtrl.text.trim().isEmpty
                ? null
                : _instagramCtrl.text.trim(),
            tiktokUrl: _tiktokCtrl.text.trim().isEmpty
                ? null
                : _tiktokCtrl.text.trim(),
            facebookUrl: _facebookCtrl.text.trim().isEmpty
                ? null
                : _facebookCtrl.text.trim(),
          );
      if (mounted) {
        setState(() => _socialChanged = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redes sociales guardadas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSavingSocial = false);
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _SocialField extends StatelessWidget {
  const _SocialField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: color, size: 20),
        border: const OutlineInputBorder(),
        filled: true,
      ),
    );
  }
}
