import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../controllers/servicios_controller.dart';
import '../models/servicio_item.dart';
import 'tabs/custom_mode.dart';

void showServiceDetailPanel(
  BuildContext context,
  ServiciosKey key,
  ServicioItem service,
) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      barrierDismissible: true,
      pageBuilder: (_, _, _) =>
          _ServiceDetailPanel(servKey: key, service: service),
      transitionsBuilder: (_, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    ),
  );
}

class _ServiceDetailPanel extends ConsumerStatefulWidget {
  const _ServiceDetailPanel({required this.servKey, required this.service});

  final ServiciosKey servKey;
  final ServicioItem service;

  @override
  ConsumerState<_ServiceDetailPanel> createState() =>
      _ServiceDetailPanelState();
}

class _ServiceDetailPanelState extends ConsumerState<_ServiceDetailPanel> {
  CustomFormData? _formData;
  bool _isSaving = false;

  Future<void> _archive() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(serviciosProvider(widget.servKey).notifier)
          .remove(widget.service.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _save() async {
    final data = _formData;
    if (data == null || !data.isValid) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(serviciosProvider(widget.servKey).notifier)
          .updateService(
            id: widget.service.id,
            nombre: data.name,
            descripcion: data.description.isEmpty ? null : data.description,
            duracionMin: data.durationMinutes,
            precio: data.priceUyu,
            activo: widget.service.active,
            extras: ServicioExtras(
              flexibleDuration: data.flexibleDuration,
              priceFrom: data.priceFrom,
              schedulingMode: data.schedulingMode,
              professionalIds: data.professionalIds,
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final state = ref.watch(serviciosProvider(widget.servKey));

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 520,
        child: Material(
          color: Colors.white,
          elevation: 0,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: KTokens.border)),
            ),
            child: Column(
              children: [
                _DetailHeader(
                  service: s,
                  onClose: () => Navigator.of(context).pop(),
                ),
                const Divider(height: 1, color: KTokens.border),
                Expanded(
                  child: CustomMode(
                    staff: state.staff,
                    initial: s,
                    servKey: widget.servKey,
                    onStaffListChanged: () => ref
                        .read(serviciosProvider(widget.servKey).notifier)
                        .reload(),
                    onChanged: (data) => setState(() => _formData = data),
                  ),
                ),
                _DetailFooter(
                  isSaving: _isSaving,
                  hasChanges: _formData != null,
                  onArchive: _isSaving ? null : _archive,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: (_formData?.isValid ?? false) && !_isSaving
                      ? _save
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.service, required this.onClose});

  final ServicioItem service;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EDITAR SERVICIO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: KTokens.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.name,
                  style: KTokens.tHero,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: KTokens.inkMuted,
            onPressed: onClose,
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

class _DetailFooter extends StatelessWidget {
  const _DetailFooter({
    required this.isSaving,
    required this.hasChanges,
    required this.onArchive,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final bool hasChanges;
  final VoidCallback? onArchive;
  final VoidCallback onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: KTokens.border)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: onArchive,
            style: TextButton.styleFrom(
              foregroundColor: KTokens.excClosed,
              textStyle: GoogleFonts.inter(fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Archivar servicio'),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: isSaving ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: KTokens.ink,
              side: const BorderSide(color: KTokens.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              textStyle: GoogleFonts.inter(fontSize: 13),
            ),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: KTokens.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: KTokens.border,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              textStyle:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
