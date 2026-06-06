import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/service_scheduling_mode.dart';
import '../../../models/agenda/staff_member.dart';
import '../../agenda/equipo/widgets/add_member_panel.dart';
import '../../agenda/register/konecta_tokens.dart';
import '../../agenda/shared/k_button.dart';
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
  bool _pickingScheduling = false;
  bool _isSaving = false;
  bool _addingMember = false;

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

  void _openSchedulingStep() {
    if (_selectedTemplateIds.isEmpty) return;
    setState(() => _pickingScheduling = true);
  }

  void _backFromScheduling() {
    setState(() => _pickingScheduling = false);
  }

  Future<void> _createSuggested(ServiceSchedulingMode mode) async {
    final state = ref.read(serviciosProvider(widget.servKey));
    final notifier = ref.read(serviciosProvider(widget.servKey).notifier);
    final templates = TemplateCatalog.forCategories(state.categories)
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
            schedulingMode: mode,
            professionalIds: const [],
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
    final state = ref.watch(serviciosProvider(widget.servKey));
    final categories = state.categories;
    final existingNames =
        state.items.map((s) => s.name.toLowerCase()).toSet();
    final isOtra = state.isOnlyOtra;
    final isSuggestedTab = !isOtra && _tabCtrl.index == 0;
    final canConfirm = isSuggestedTab
        ? _selectedTemplateIds.isNotEmpty
        : (_customData?.isValid ?? false);

    final customMode = CustomMode(
      staff: state.staff,
      servKey: widget.servKey,
      onStaffListChanged: () =>
          ref.read(serviciosProvider(widget.servKey).notifier).reload(),
      onChanged: (data) => setState(() => _customData = data),
      onAddProfessional: () => setState(() => _addingMember = true),
    );

    // Mientras se crea un miembro, reemplazamos el panel entero con el
    // formulario de miembro embebido — sin superposición de paneles.
    if (_addingMember) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 520,
          child: AddMemberPanel(
            embedMode: true,
            equipoKey: (
              tenantId: widget.servKey.tenantId,
              businessId: widget.servKey.businessId,
            ),
            onCancel: () => setState(() => _addingMember = false),
            onDone: () {
              setState(() => _addingMember = false);
              ref.read(serviciosProvider(widget.servKey).notifier).reload();
            },
          ),
        ),
      );
    }

    final Widget body;
    final bool showTabs;
    if (_pickingScheduling) {
      body = _SchedulingChoiceStep(
        count: _selectedTemplateIds.length,
        isSaving: _isSaving,
        onPick: _isSaving ? null : _createSuggested,
      );
      showTabs = false;
    } else if (isOtra) {
      body = customMode;
      showTabs = false;
    } else {
      body = TabBarView(
        controller: _tabCtrl,
        children: [
          SuggestedMode(
            categories: categories,
            existingNames: existingNames,
            onSelectionChanged: (ids) =>
                setState(() => _selectedTemplateIds = ids),
            onSwitchToCustom: () => _tabCtrl.animateTo(1),
          ),
          customMode,
        ],
      );
      showTabs = true;
    }

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
                  categories: categories,
                  pickingScheduling: _pickingScheduling,
                  onClose: () => Navigator.of(context).pop(),
                ),
                if (showTabs)
                  Container(
                    decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: KTokens.border)),
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
                Expanded(child: body),
                _PanelFooter(
                  pickingScheduling: _pickingScheduling,
                  isSuggestedTab: isSuggestedTab,
                  selectedCount: _selectedTemplateIds.length,
                  canConfirm: canConfirm,
                  isSaving: _isSaving,
                  onCancel: () => Navigator.of(context).pop(),
                  onBack: _backFromScheduling,
                  onConfirm: isSuggestedTab ? _openSchedulingStep : _createCustom,
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
  const _PanelHeader({
    required this.categories,
    required this.pickingScheduling,
    required this.onClose,
  });

  final List<BusinessCategory> categories;
  final bool pickingScheduling;
  final VoidCallback onClose;

  String _label() {
    final names = categories.map((c) => c.displayName).toList();
    if (names.length <= 1) return names.isEmpty ? '' : names.first;
    if (names.length == 2) return '${names[0]} y ${names[1]}';
    return '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
  }

  @override
  Widget build(BuildContext context) {
    final isOnlyOtra =
        categories.length == 1 && categories.first == BusinessCategory.otra;
    final eyebrow = pickingScheduling ? 'PASO 2 · CÓMO SE AGENDAN' : 'NUEVO SERVICIO';
    final title = pickingScheduling
        ? '¿Cómo se agendan?'
        : 'Agrega lo que ofrecés';
    final subtitle = pickingScheduling
        ? 'Elegí cómo se reservan los servicios que vas a crear.'
        : (isOnlyOtra
            ? 'Configurá tu servicio a medida.'
            : 'Empezá desde sugerencias para ${_label()} o creá uno desde cero.');

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
                  eyebrow,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: KTokens.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: KTokens.tHero,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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

// ─── Scheduling choice step ───────────────────────────────────────────────────

class _SchedulingChoiceStep extends StatelessWidget {
  const _SchedulingChoiceStep({
    required this.count,
    required this.isSaving,
    required this.onPick,
  });

  final int count;
  final bool isSaving;
  final ValueChanged<ServiceSchedulingMode>? onPick;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Se aplica a los $count servicio${count > 1 ? 's' : ''} que seleccionaste. '
            'Podés cambiarlo después en cada servicio.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: KTokens.inkMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _ChoiceCard(
            title: 'Agenda general',
            subtitle:
                'El cliente reserva sin elegir profesional. Cualquiera del equipo puede atenderlo.',
            icon: Icons.storefront_outlined,
            enabled: !isSaving,
            onTap: () => onPick?.call(ServiceSchedulingMode.general),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            title: 'Por profesional',
            subtitle:
                'El cliente elige a quién reservar. Asignás los profesionales después desde cada servicio o desde Equipo.',
            icon: Icons.people_outline_rounded,
            enabled: !isSaving,
            onTap: () => onPick?.call(ServiceSchedulingMode.byStaff),
          ),
          if (isSaving) ...[
            const SizedBox(height: 20),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: KTokens.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: KTokens.surface,
            border: Border.all(color: KTokens.border, width: 1.0),
            borderRadius: BorderRadius.circular(KTokens.rSm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: KTokens.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: KTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: KTokens.inkMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: KTokens.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _PanelFooter extends StatelessWidget {
  const _PanelFooter({
    required this.pickingScheduling,
    required this.isSuggestedTab,
    required this.selectedCount,
    required this.canConfirm,
    required this.isSaving,
    required this.onCancel,
    required this.onBack,
    required this.onConfirm,
  });

  final bool pickingScheduling;
  final bool isSuggestedTab;
  final int selectedCount;
  final bool canConfirm;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    if (pickingScheduling) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: KTokens.border)),
        ),
        child: Row(
          children: [
            KButton.secondary(
              label: 'Atrás',
              icon: Icons.arrow_back_rounded,
              onPressed: isSaving ? null : onBack,
            ),
          ],
        ),
      );
    }

    final label = isSuggestedTab
        ? (selectedCount == 0
            ? 'Agregar servicios'
            : 'Agregar $selectedCount servicio${selectedCount > 1 ? 's' : ''}')
        : 'Crear servicio';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: KTokens.border)),
      ),
      child: Row(
        children: [
          KButton.secondary(
            label: 'Cancelar',
            onPressed: isSaving ? null : onCancel,
          ),
          const Spacer(),
          KButton.accent(
            label: label,
            trailing: Icons.arrow_forward_rounded,
            loading: isSaving,
            onPressed: canConfirm ? onConfirm : null,
          ),
        ],
      ),
    );
  }
}

// Exported type alias for staff in panels
typedef PanelStaff = List<StaffMember>;
