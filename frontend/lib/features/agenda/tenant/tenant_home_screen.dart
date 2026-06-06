import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/navigation/agenda_tenant_nav.dart';
import '../../../models/agenda/business.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/public/public_categories_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../../../features/inicio/screens/inicio_screen.dart';
import '../register/konecta_tokens.dart';
import '../shared/k_mobile_top_bar.dart';
import 'widgets/agenda_left_nav.dart';
import 'widgets/business_form_dialog.dart';
import 'widgets/category_multi_select_dialog.dart';
import 'widgets/agenda_section.dart';

// ── Palette (for business initials) ──────────────────────────────────────────
const _palette = [
  Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899),
  Color(0xFF14B8A6), Color(0xFF22C55E), Color(0xFFF59E0B),
  Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFF84CC16),
];

// ── Layout constants ──────────────────────────────────────────────────────────
const _kBreakpoint = 1024.0;

// ── Screen ────────────────────────────────────────────────────────────────────

class TenantHomeScreen extends ConsumerStatefulWidget {
  const TenantHomeScreen({super.key, required this.tenantId, this.businessId});

  final String tenantId;
  final String? businessId;

  @override
  ConsumerState<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends ConsumerState<TenantHomeScreen> {
  final _instagramCtrl = TextEditingController();
  final _tiktokCtrl    = TextEditingController();
  final _facebookCtrl  = TextEditingController();
  bool    _socialChanged  = false;
  bool    _isSavingSocial = false;
  String? _initBusinessId;
  String? _dashboardBusinessId;

  @override
  void initState() {
    super.initState();
    if (widget.businessId != null) {
      _dashboardBusinessId = widget.businessId;
    }
  }

  @override
  void dispose() {
    _instagramCtrl.dispose();
    _tiktokCtrl.dispose();
    _facebookCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(Business b) {
    if (_initBusinessId == b.id) return;
    _initBusinessId = b.id;
    _instagramCtrl.text = b.instagramUrl ?? '';
    _tiktokCtrl.text    = b.tiktokUrl ?? '';
    _facebookCtrl.text  = b.facebookUrl ?? '';
  }

  Future<void> _saveSocial(Business b) async {
    setState(() => _isSavingSocial = true);
    try {
      await ref.read(businessesProvider(widget.tenantId).notifier).update(
        businessId:   b.id,
        nombre:       b.nombre,
        descripcion:  b.descripcion,
        searchTags:   b.searchTags,
        logoUrl:      b.logoUrl,
        colorPrimario: b.colorPrimario,
        instagramUrl: _instagramCtrl.text.trim().isEmpty ? null : _instagramCtrl.text.trim(),
        tiktokUrl:    _tiktokCtrl.text.trim().isEmpty    ? null : _tiktokCtrl.text.trim(),
        facebookUrl:  _facebookCtrl.text.trim().isEmpty  ? null : _facebookCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _socialChanged   = false;
          _initBusinessId  = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redes sociales actualizadas')),
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

  Future<void> _createBusiness(BuildContext context) async {
    final result = await showDialog<BusinessFormResult>(
      context: context,
      builder: (_) => const BusinessFormDialog(),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(businessesProvider(widget.tenantId).notifier).create(
        nombre:      result.nombre,
        descripcion: result.descripcion,
        searchTags:  result.searchTags,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _editBusiness(BuildContext context, Business b) async {
    final result = await showDialog<BusinessFormResult>(
      context: context,
      builder: (_) => BusinessFormDialog(initial: b),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(businessesProvider(widget.tenantId).notifier).update(
        businessId:   b.id,
        nombre:       result.nombre,
        descripcion:  result.descripcion,
        searchTags:   result.searchTags,
        logoUrl:      b.logoUrl,
        colorPrimario: b.colorPrimario,
        instagramUrl: b.instagramUrl,
        tiktokUrl:    b.tiktokUrl,
        facebookUrl:  b.facebookUrl,
      );
      if (mounted) setState(() => _initBusinessId = null);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(businessesProvider(widget.tenantId));
    final userAsync = ref.watch(agendaUserProvider);
    final googleName = ref.watch(authStateProvider).user?.name?.trim();
    final nombre = (googleName != null && googleName.isNotEmpty)
        ? googleName
        : userAsync.valueOrNull?.nombre;
    final isWide    = MediaQuery.sizeOf(context).width >= _kBreakpoint;

    void onBack() =>
        context.canPop() ? context.pop() : context.go('/agenda/panel');

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: KTokens.bg,
        body: const AgendaLoadingView(),
      );
    }
    if (state.error != null) {
      return Scaffold(
        backgroundColor: KTokens.bg,
        body: AgendaErrorView(
          message: state.error!,
          onRetry: () =>
              ref.read(businessesProvider(widget.tenantId).notifier).load(),
        ),
      );
    }

    final first = state.items.isEmpty ? null : state.items.first;
    if (first != null) _syncControllers(first);
    final effectiveDashboardBusinessId =
        _dashboardBusinessId ?? (state.items.isEmpty ? null : state.items.first.id);

    if (isWide) {
      return Scaffold(
        backgroundColor: KTokens.bg,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AgendaLeftNav(
              nombre:       nombre,
              businessName: first?.nombre,
              tenantId:     widget.tenantId,
              businessId:   first?.id,
            ),
            Expanded(
              child: _MainContent(
                tenantId:            widget.tenantId,
                businesses:          state.items,
                dashboardBusinessId: effectiveDashboardBusinessId,
                nombre:              nombre,
                isWide:              true,
                onAdd:               () => _createBusiness(context),
                onTap:               (b) => navigateAgendaTenantBusiness(
                  context,
                  ref,
                  b.id,
                ),
                onFilterSelect: (b) => setState(() =>
                  _dashboardBusinessId =
                      _dashboardBusinessId == b.id ? null : b.id,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile ────────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: KTokens.bg,
      drawer: Drawer(
        width: kAgendaNavWidth,
        child: AgendaLeftNav(
          nombre:       nombre,
          businessName: first?.nombre,
          tenantId:     widget.tenantId,
          businessId:   first?.id,
        ),
      ),
      body: _MainContent(
        tenantId:            widget.tenantId,
        businesses:          state.items,
        dashboardBusinessId: effectiveDashboardBusinessId,
        nombre:              nombre,
        isWide:              false,
        onAdd:               () => _createBusiness(context),
        onTap:               (b) => navigateAgendaTenantBusiness(
          context,
          ref,
          b.id,
        ),
        onFilterSelect: (b) => setState(() =>
          _dashboardBusinessId =
              _dashboardBusinessId == b.id ? null : b.id,
        ),
        onBack: onBack,
      ),
    );
  }
}

// ── Main Content ──────────────────────────────────────────────────────────────

class _MainContent extends StatelessWidget {
  const _MainContent({
    required this.tenantId,
    required this.businesses,
    required this.dashboardBusinessId,
    required this.nombre,
    required this.isWide,
    required this.onAdd,
    required this.onTap,
    required this.onFilterSelect,
    this.onBack,
  });

  final String           tenantId;
  final List<Business>   businesses;
  final String?          dashboardBusinessId;
  final String?          nombre;
  final bool             isWide;
  final VoidCallback     onAdd;
  final void Function(Business) onTap;
  final void Function(Business) onFilterSelect;
  final VoidCallback?    onBack;

  @override
  Widget build(BuildContext context) {
    final hPad = isWide ? 32.0 : 20.0;
    final section = GoRouterState.of(context).uri.queryParameters['section'] ?? '';
    final showAgenda = section == 'agenda';

    Widget body;
    if (showAgenda) {
      // Devolver directo para que el padre proporcione altura acotada.
      body = Padding(
        padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
        child: AgendaSection(
          tenantId: tenantId,
          businesses: businesses,
          businessId: dashboardBusinessId,
          onBusinessSelected: (id) => onFilterSelect(
            businesses.firstWhere((b) => b.id == id),
          ),
        ),
      );
    } else {
      body = InicioScreen(
        businessId: dashboardBusinessId ?? '',
        tenantId: tenantId,
        businessName: businesses.isEmpty ? null : businesses.first.nombre,
        ownerName: nombre,
      );
    }

    if (!isWide) {
      return Column(
        children: [
          const KMobileTopBar(),
          Expanded(child: body),
        ],
      );
    }

    return body;
  }
}

// ── Card base ─────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        KTokens.surface,
        borderRadius: BorderRadius.circular(KTokens.rMd),
        border:       Border.all(color: KTokens.border),
      ),
      padding: const EdgeInsets.all(20),
      child:   child,
    );
  }
}

// ── Info Card — kept for use in business detail screen ────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.business, required this.onEdit});

  final Business     business;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Info', style: KTokens.tEyebrow),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: KTokens.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (business.descripcion != null &&
              business.descripcion!.isNotEmpty) ...[
            Text(
              business.descripcion!,
              style: GoogleFonts.inter(fontSize: 13, color: KTokens.ink),
            ),
            const SizedBox(height: 10),
          ],
          if (business.searchTags.isEmpty)
            Text(
              'Sin tags',
              style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkMuted),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in business.searchTags) _Tag(label: tag),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Categories Card — kept for use in business detail screen ──────────────────

class _CategoriesCard extends ConsumerWidget {
  const _CategoriesCard({
    required this.business,
    required this.tenantId,
  });

  final Business business;
  final String   tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(publicCategoriesProvider);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Categorías', style: KTokens.tEyebrow),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final selected = await CategoryMultiSelectDialog.show(
                    context,
                    allCategories: categoriesAsync.valueOrNull ?? [],
                    selectedSlugs: business.categorias,
                  );
                  if (selected == null || !context.mounted) return;
                  try {
                    await ref
                        .read(businessesProvider(tenantId).notifier)
                        .associateCategories(
                          businessId:  business.id,
                          categoryIds: selected,
                        );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: KTokens.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (business.categorias.isEmpty)
            Text(
              'Sin categorías',
              style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkMuted),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final slug in business.categorias)
                  _Tag(
                    label:     slug,
                    color:     KTokens.accentSoft,
                    textColor: KTokens.accent,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Social Card — kept for use in business detail screen ──────────────────────

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.business,
    required this.instagramCtrl,
    required this.tiktokCtrl,
    required this.facebookCtrl,
    required this.changed,
    required this.saving,
    required this.onChanged,
    required this.onSave,
  });

  final Business              business;
  final TextEditingController instagramCtrl;
  final TextEditingController tiktokCtrl;
  final TextEditingController facebookCtrl;
  final bool                  changed;
  final bool                  saving;
  final VoidCallback          onChanged;
  final VoidCallback          onSave;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Redes sociales', style: KTokens.tEyebrow),
          const SizedBox(height: 14),
          _SocialRow(
            color:      const Color(0xFFE1306C),
            icon:       Icons.camera_alt_outlined,
            hint:       'instagram.com/tu-negocio',
            controller: instagramCtrl,
            onChanged:  onChanged,
          ),
          const SizedBox(height: 12),
          _SocialRow(
            color:      Colors.black87,
            icon:       Icons.music_note_outlined,
            hint:       'tiktok.com/@tu-negocio',
            controller: tiktokCtrl,
            onChanged:  onChanged,
          ),
          const SizedBox(height: 12),
          _SocialRow(
            color:      const Color(0xFF1877F2),
            icon:       Icons.facebook_outlined,
            hint:       'facebook.com/tu-negocio',
            controller: facebookCtrl,
            onChanged:  onChanged,
          ),
          if (changed) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KTokens.ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KTokens.rMd),
                  ),
                ),
                child: Text(
                  saving ? 'Guardando...' : 'Guardar',
                  style: GoogleFonts.inter(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    color:      Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({
    required this.color,
    required this.icon,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final Color                 color;
  final IconData              icon;
  final String                hint;
  final TextEditingController controller;
  final VoidCallback          onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width:  32,
          height: 32,
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged:  (_) => onChanged(),
            style:      GoogleFonts.inter(fontSize: 13, color: KTokens.ink),
            decoration: InputDecoration(
              isDense:        true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              hintText:       hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                color:    KTokens.inkMuted,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: KTokens.border),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: KTokens.accent, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Business Tile — kept for use in business detail or location screens ───────

class _BusinessTile extends StatelessWidget {
  const _BusinessTile({
    required this.business,
    required this.onTap,
    required this.isLast,
  });

  final Business     business;
  final VoidCallback onTap;
  final bool         isLast;

  Color get _color => _palette[business.nombre.hashCode.abs() % _palette.length];

  String get _locationText {
    final geo = business.searchTags.take(2).toList();
    return geo.isEmpty ? '' : geo.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final location = _locationText;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: KTokens.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color:        _color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.nombre,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: KTokens.ink,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: KTokens.inkSoft,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: business.activo
                    ? const Color(0xFF22C55E).withValues(alpha: 0.10)
                    : KTokens.border,
                borderRadius: BorderRadius.circular(KTokens.rPill),
              ),
              child: Text(
                business.activo ? 'Activo' : 'Inactivo',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: business.activo
                      ? const Color(0xFF16A34A)
                      : KTokens.inkMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 16, color: KTokens.inkSoft),
          ],
        ),
      ),
    );
  }
}

// ── Tag chip ──────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color, this.textColor});

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color ?? KTokens.border,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize:   11,
          fontWeight: FontWeight.w500,
          color:      textColor ?? KTokens.inkMuted,
        ),
      ),
    );
  }
}
