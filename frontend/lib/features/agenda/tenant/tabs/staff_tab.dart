// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/staff_member.dart';
import '../../../../providers/agenda/tenant/business_staff_provider.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';

typedef _StaffKey = ({String tenantId, String businessId});

class StaffTab extends ConsumerStatefulWidget {
  const StaffTab({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  ConsumerState<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends ConsumerState<StaffTab> {
  String? _uploadingMemberId;

  _StaffKey get _key =>
      (tenantId: widget.tenantId, businessId: widget.businessId);

  void _pickAndUploadAvatar(StaffMember member) {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((_) async {
      final file = input.files?.first;
      if (file == null) return;
      setState(() => _uploadingMemberId = member.id);
      try {
        final bytes = await _readFileBytes(file);
        final ok = await ref
            .read(businessStaffProvider(_key).notifier)
            .uploadAvatar(member.id, bytes, file.name);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ref.read(businessStaffProvider(_key)).error ??
                'Error al subir imagen'),
            backgroundColor: Colors.red.shade700,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _uploadingMemberId = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessStaffProvider(_key));

    if (state.isLoading) {
      return const AgendaLoadingView(message: 'Cargando equipo...');
    }
    if (state.error != null && state.members.isEmpty) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(businessStaffProvider(_key).notifier).load(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Equipo de trabajo',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      '${state.members.length} miembro${state.members.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                icon: state.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Agregar miembro'),
                onPressed:
                    state.isSaving ? null : () => _showAddDialog(context),
              ),
            ],
          ),
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text(state.error!,
                style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          if (state.members.isEmpty)
            const Expanded(
              child: AgendaEmptyState(
                icon: Icons.people_outline,
                title: 'Sin miembros todavía',
                subtitle: 'Agrega miembros de tu equipo de trabajo',
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: state.members
                      .map((m) => _StaffCard(
                            member: m,
                            isUploading: _uploadingMemberId == m.id,
                            isSaving: state.isSaving,
                            onUploadAvatar: () => _pickAndUploadAvatar(m),
                            onEdit: () => _showEditDialog(context, m),
                            onDeactivate: () => _confirmDeactivate(context, m),
                          ))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final result = await showDialog<_MemberFormResult>(
      context: context,
      builder: (_) => const _AddMemberDialog(),
    );
    if (result == null || !context.mounted) return;

    final created = await ref
        .read(businessStaffProvider(_key).notifier)
        .addMember(result.nombre, result.rol, null);

    if (created == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ref.read(businessStaffProvider(_key)).error ??
              'Error al guardar'),
          backgroundColor: Colors.red.shade700,
        ));
      }
      return;
    }

    if (result.imageBytes != null && result.fileName != null) {
      setState(() => _uploadingMemberId = created.id);
      try {
        await ref
            .read(businessStaffProvider(_key).notifier)
            .uploadAvatar(created.id, result.imageBytes!, result.fileName!);
      } finally {
        if (mounted) setState(() => _uploadingMemberId = null);
      }
    }
  }

  void _showEditDialog(BuildContext context, StaffMember member) {
    final nombreCtrl = TextEditingController(text: member.nombre);
    final rolCtrl = TextEditingController(text: member.rol ?? '');
    bool activo = member.activo;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Editar miembro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rolCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cargo (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Activo'),
                value: activo,
                onChanged: (v) => setLocal(() => activo = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final nombre = nombreCtrl.text.trim();
                if (nombre.isEmpty) return;
                Navigator.of(ctx).pop();
                final ok = await ref
                    .read(businessStaffProvider(_key).notifier)
                    .updateMember(
                      member.id,
                      nombre,
                      rolCtrl.text.trim().isEmpty ? null : rolCtrl.text.trim(),
                      member.avatarUrl,
                      activo,
                    );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        ref.read(businessStaffProvider(_key)).error ??
                            'Error al actualizar'),
                    backgroundColor: Colors.red.shade700,
                  ));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, StaffMember member) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar miembro'),
        content: Text(
            '¿Seguro que querés desactivar a "${member.nombre}"? '
            'Esta acción no borra el historial de reservas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(businessStaffProvider(_key).notifier)
                  .deactivate(member.id);
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add member dialog with inline avatar picker
// ─────────────────────────────────────────────────────────────────────────────

class _MemberFormResult {
  final String nombre;
  final String? rol;
  final Uint8List? imageBytes;
  final String? fileName;

  const _MemberFormResult({
    required this.nombre,
    this.rol,
    this.imageBytes,
    this.fileName,
  });
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _nombreCtrl = TextEditingController();
  final _rolCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String? _fileName;
  bool _pickingImage = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rolCtrl.dispose();
    super.dispose();
  }

  void _pickImage() {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((_) async {
      final file = input.files?.first;
      if (file == null) return;
      setState(() => _pickingImage = true);
      try {
        final bytes = await _readFileBytes(file);
        setState(() {
          _imageBytes = Uint8List.fromList(bytes);
          _fileName = file.name;
        });
      } catch (_) {
        // ignore pick errors
      } finally {
        if (mounted) setState(() => _pickingImage = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _nombreCtrl.text.trim();
    final initials = nombre.isEmpty
        ? '?'
        : nombre
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

    return AlertDialog(
      title: const Text('Agregar miembro'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Avatar picker ────────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE0E7FF),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _pickingImage
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tocar para agregar foto',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            // ── Form fields ──────────────────────────────────────────────
            TextField(
              controller: _nombreCtrl,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rolCtrl,
              decoration: const InputDecoration(
                labelText: 'Cargo (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final nombre = _nombreCtrl.text.trim();
            if (nombre.isEmpty) return;
            Navigator.of(context).pop(_MemberFormResult(
              nombre: nombre,
              rol: _rolCtrl.text.trim().isEmpty ? null : _rolCtrl.text.trim(),
              imageBytes: _imageBytes,
              fileName: _fileName,
            ));
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staff card
// ─────────────────────────────────────────────────────────────────────────────

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.member,
    required this.isUploading,
    required this.isSaving,
    required this.onUploadAvatar,
    required this.onEdit,
    required this.onDeactivate,
  });

  final StaffMember member;
  final bool isUploading;
  final bool isSaving;
  final VoidCallback onUploadAvatar;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  String get _initials {
    final words = member.nombre.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return member.nombre
        .substring(0, member.nombre.length.clamp(1, 2))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _AvatarCircle(
                avatarUrl: member.avatarUrl,
                initials: _initials,
                size: 72,
                isUploading: isUploading,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: (isSaving || isUploading) ? null : onUploadAvatar,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            member.nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, height: 1.2),
          ),
          if (member.rol != null && member.rol!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              member.rol!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color:
                  member.activo ? Colors.green.shade50 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: member.activo
                    ? Colors.green.shade300
                    : Colors.grey.shade400,
              ),
            ),
            child: Text(
              member.activo ? 'Activo' : 'Inactivo',
              style: TextStyle(
                fontSize: 11,
                color: member.activo
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: isSaving ? null : onEdit,
                tooltip: 'Editar',
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: Icon(Icons.person_off_outlined,
                    size: 18, color: Colors.orange.shade600),
                onPressed: isSaving ? null : onDeactivate,
                tooltip: 'Desactivar',
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<List<int>> _readFileBytes(html.File file) async {
  final reader = html.FileReader();
  reader.readAsDataUrl(file);
  await reader.onLoad.first;
  final dataUrl = reader.result as String;
  final comma = dataUrl.indexOf(',');
  return base64.decode(dataUrl.substring(comma + 1));
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.avatarUrl,
    required this.initials,
    required this.size,
    required this.isUploading,
  });

  final String? avatarUrl;
  final String initials;
  final double size;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE0E7FF),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null && avatarUrl!.startsWith('http')
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Center(
                      child: Text(initials,
                          style: TextStyle(
                              color: const Color(0xFF6366F1),
                              fontSize: size * 0.3,
                              fontWeight: FontWeight.w800)),
                    ),
                  )
                : Center(
                    child: Text(initials,
                        style: TextStyle(
                            color: const Color(0xFF6366F1),
                            fontSize: size * 0.3,
                            fontWeight: FontWeight.w800)),
                  ),
          ),
          if (isUploading)
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x88000000),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
