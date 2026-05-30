import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/staff_member.dart';
import '../../agenda/register/konecta_tokens.dart';
import '../controllers/servicios_controller.dart';
import '../data/template_catalog.dart';
import '../models/business_category.dart';
import 'tabs/custom_mode.dart';
import 'tabs/suggested_mode.dart';

void showAddServicePanel(
  BuildContext context,
  ServiciosKey key,
) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      barrierDismissible: true,
      pageBuilder: (_, _, _) => _AddServicePanel(servKey: key),
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

class _AddServicePanel extends ConsumerStatefulWidget {
  const _AddServicePanel({required this.servKey});

  final ServiciosKey servKey;

  @override
  ConsumerState<_AddServicePanel> createState() => _AddServicePanelState();
}

class _AddServicePanelState extends ConsumerState<_AddServicePanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  Set<String> _selectedTemplateIds = {};
  CustomFormData? _customData;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _addSuggested() async {
    final state = ref.read(serviciosProvider(widget.servKey));
    final notifier = ref.read(serviciosProvider(widget.servKey).notifier);
    final templates = TemplateCatalog.forCategory(state.category)
        .where((t) => _selectedTemplateIds.contains(t.id))
        .toList();

    setState(() => _isSaving = true);
    try {
      for (final t in templates) {
        await notifier.createService(
          nombre: t.name,
          descripcion: t.description,
          duracionMin: t.defaultDurationMinutes,
          precio: t.defaultPriceUyu,
          extras: ServicioExtras(
            flexibleDuration: t.defaultFlexibleDuration,
            priceFrom: t.defaultPriceFrom,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _createCustom() async {
    final data = _customData;
    if (data == null || !data.isValid) return;
    final notifier = ref.read(serviciosProvider(widget.servKey).notifier);

    setState(() => _isSaving = true);
    try {
      await notifier.createService(
        nombre: data.name,
        descripcion: data.description.isEmpty ? null : data.description,
        duracionMin: data.durationMinutes,
        precio: data.priceUyu,
        extras: ServicioExtras(
          flexibleDuration: data.flexibleDuration,
          priceFrom: data.priceFrom,
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
    final state = ref.watch(serviciosProvider(widget.servKey));
    final category = state.category;
    final existingNames =
        state.items.map((s) => s.name.toLowerCase()).toSet();
    final isSuggestedTab = _tabCtrl.index == 0;
    final canConfirm = isSuggestedTab
        ? _selectedTemplateIds.isNotEmpty
        : (_customData?.isValid ?? false);

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
                _PanelHeader(
                  category: category,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: KTokens.border)),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicatorColor: KTokens.accent,
                    indicatorWeight: 2,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                    labelColor: KTokens.accent,
                    unselectedLabelColor: KTokens.inkMuted,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Desde sugerencias'),
                      Tab(text: 'Desde cero'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      SuggestedMode(
                        category: category,
                        existingNames: existingNames,
                        onSelectionChanged: (ids) =>
                            setState(() => _selectedTemplateIds = ids),
                        onSwitchToCustom: () => _tabCtrl.animateTo(1),
                      ),
                      CustomMode(
                        staff: state.staff,
                        onChanged: (data) =>
                            setState(() => _customData = data),
                      ),
                    ],
                  ),
                ),
                _PanelFooter(
                  isSuggestedTab: isSuggestedTab,
                  selectedCount: _selectedTemplateIds.length,
                  canConfirm: canConfirm,
                  isSaving: _isSaving,
                  onCancel: () => Navigator.of(context).pop(),
                  onConfirm:
                      isSuggestedTab ? _addSuggested : _createCustom,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.category, required this.onClose});

  final BusinessCategory category;
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
                  'NUEVO SERVICIO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: KTokens.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agrega lo que ofrecés',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                    color: KTokens.ink,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Empezá desde sugerencias para ${category.displayName} o creá uno desde cero.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: KTokens.inkMuted, height: 1.5),
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

class _PanelFooter extends StatelessWidget {
  const _PanelFooter({
    required this.isSuggestedTab,
    required this.selectedCount,
    required this.canConfirm,
    required this.isSaving,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool isSuggestedTab;
  final int selectedCount;
  final bool canConfirm;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final label = isSuggestedTab
        ? (selectedCount == 0
            ? 'Agregar servicios'
            : 'Agregar $selectedCount servicio${selectedCount > 1 ? 's' : ''}')
        : 'Crear servicio →';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: KTokens.border)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: isSaving ? null : onCancel,
            style: TextButton.styleFrom(
              foregroundColor: KTokens.inkMuted,
              textStyle: GoogleFonts.inter(fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Cancelar'),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: (canConfirm && !isSaving) ? onConfirm : null,
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
                : Text(label),
          ),
        ],
      ),
    );
  }
}

// Exported type alias for staff in panels
typedef PanelStaff = List<StaffMember>;
