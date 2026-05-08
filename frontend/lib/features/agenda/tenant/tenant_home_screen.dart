import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import '../../../features/agenda/navigation/agenda_tenant_nav.dart';
import '../../../models/agenda/business.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import '../../../providers/agenda/public/public_categories_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../register/konecta_tokens.dart';
import 'widgets/business_form_dialog.dart';
import 'widgets/category_multi_select_dialog.dart';
import 'widgets/dashboard_section.dart';

// ── Palette (for business initials) ──────────────────────────────────────────
const _palette = [
  Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899),
  Color(0xFF14B8A6), Color(0xFF22C55E), Color(0xFFF59E0B),
  Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFF84CC16),
];

// ── Layout constants ──────────────────────────────────────────────────────────
const _kBreakpoint = 1024.0;
const _kNavWidth   = 200.0;
const _kPanelWidth = 280.0;

// ── Screen ────────────────────────────────────────────────────────────────────

class TenantHomeScreen extends ConsumerStatefulWidget {
  const TenantHomeScreen({super.key, required this.tenantId});

  final String tenantId;

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
    final nombre    = userAsync.valueOrNull?.nombre;
    final isWide    = MediaQuery.sizeOf(context).width >= _kBreakpoint;

    void onBack() =>
        context.canPop() ? context.pop() : context.go('/home');

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

    if (isWide) {
      return Scaffold(
        backgroundColor: KTokens.bg,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LeftNav(
              nombre:       nombre,
              businessName: first?.nombre,
              tenantId:     widget.tenantId,
              businessId:   first?.id,
            ),
            Expanded(
              child: _MainContent(
                tenantId:            widget.tenantId,
                businesses:          state.items,
                dashboardBusinessId: _dashboardBusinessId,
                nombre:              nombre,
                isWide:              true,
                onAdd:               () => _createBusiness(context),
                onTap:               (b) => context.push(
                  agendaTenantBusinessPath(context, widget.tenantId, b.id),
                ),
                onFilterSelect: (b) => setState(() =>
                  _dashboardBusinessId =
                      _dashboardBusinessId == b.id ? null : b.id,
                ),
              ),
            ),
            _RightPanel(tenantId: widget.tenantId),
          ],
        ),
      );
    }

    // ── Mobile ────────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: KTokens.bg,
      body: _MainContent(
        tenantId:            widget.tenantId,
        businesses:          state.items,
        dashboardBusinessId: _dashboardBusinessId,
        nombre:              nombre,
        isWide:              false,
        onAdd:               () => _createBusiness(context),
        onTap:               (b) => context.push(
          agendaTenantBusinessPath(context, widget.tenantId, b.id),
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

// ── Left Nav ──────────────────────────────────────────────────────────────────

class _LeftNav extends ConsumerWidget {
  const _LeftNav({this.nombre, this.businessName, this.tenantId, this.businessId});

  final String? nombre;
  final String? businessName;
  final String? tenantId;
  final String? businessId;

  void _goTab(BuildContext context, int tab) {
    if (tenantId == null || businessId == null) return;
    context.push(
      agendaTenantBusinessPath(context, tenantId!, businessId!, tab: tab),
    );
  }

  String? _publicBookingUrl() {
    if (businessId == null) return null;
    // Flutter web usa hash routing (/#/...). La ruta pública está en router.dart.
    return '${Uri.base.origin}/#/agenda/public/business/$businessId';
  }

  Future<void> _showPublicAgendaLinkDialog(BuildContext context) async {
    final url = _publicBookingUrl();
    if (url == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Link público para que tus clientes reserven'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copiado')),
                );
              }
            },
            child: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/agenda/public/business/$businessId');
            },
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final initials = (nombre?.isNotEmpty == true)
        ? nombre![0].toUpperCase()
        : 'U';
    final loc = GoRouterState.of(context).matchedLocation;
    final selectedInicio =
        loc == '/home' || loc.startsWith('/home/businesses/');
    final selectedBots = loc.startsWith('/home/bots');

    return Container(
      width: _kNavWidth,
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border(right: BorderSide(color: KTokens.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPad + 24),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'konecta',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: KTokens.accent,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Nav items
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Inicio',
            selected: selectedInicio,
            onTap: () => context.go('/home'),
          ),
          _NavItem(
            icon: Icons.smart_toy_outlined,
            label: 'Mis bots',
            selected: selectedBots,
            onTap: () => context.go('/home/bots'),
          ),
          _NavItem(
            icon: Icons.calendar_today_outlined,
            label: 'Agenda',
            onTap: () => _showPublicAgendaLinkDialog(context),
          ),
          _NavItem(icon: Icons.people_outline,           label: 'Clientes'),
          _NavItem(
            icon:  Icons.design_services_outlined,
            label: 'Servicios',
            onTap: () => _goTab(context, 2),
          ),
          _NavItem(
            icon:  Icons.schedule_outlined,
            label: 'Horarios',
            onTap: () => _goTab(context, 0),
          ),
          _NavItem(
            icon:  Icons.group_outlined,
            label: 'Equipo',
            onTap: () => _goTab(context, 6),
          ),
          _NavItem(icon: Icons.bar_chart_outlined,       label: 'Reportes'),
          _NavItem(
            icon:  Icons.settings_outlined,
            label: 'Configuración',
            onTap: () => _goTab(context, 4),
          ),
          const Spacer(),
          // User profile
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: KTokens.bg,
              borderRadius: BorderRadius.circular(KTokens.rMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: KTokens.accentSoft,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: KTokens.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre?.isNotEmpty == true ? nombre! : 'Usuario',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: KTokens.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (businessName != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          businessName!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: KTokens.inkSoft,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: TextButton.icon(
              onPressed: () {
                ref.read(authStateProvider.notifier).signOut();
                context.go('/');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Salir'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData      icon;
  final String        label;
  final bool          selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.fromLTRB(8, 1, 8, 1),
      decoration: BoxDecoration(
        color: selected ? KTokens.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(KTokens.rMd),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? KTokens.accent : KTokens.inkSoft,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? KTokens.accent : KTokens.inkMuted,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Right Panel ───────────────────────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  const _RightPanel({required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: _kPanelWidth,
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border(left: BorderSide(color: KTokens.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topPad + 20),

          // ── PRÓXIMAS AGENDAS ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Text(
                  'PRÓXIMAS AGENDAS',
                  style: KTokens.tEyebrow.copyWith(
                    letterSpacing: 1.2,
                    color: KTokens.inkSoft,
                  ),
                ),
                const Spacer(),
                Text(
                  'Ver todos',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: KTokens.accent,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 5,
            child: _ProximasAgendasSection(),
          ),

          Divider(height: 1, color: KTokens.border),

          // ── RENDIMIENTO DE NEGOCIOS ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Text(
                  'RENDIMIENTO DE NEGOCIOS',
                  style: KTokens.tEyebrow.copyWith(
                    letterSpacing: 1.0,
                    color: KTokens.inkSoft,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  'Ver reportes',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: KTokens.accent,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 4,
            child: const _RendimientoNegociosSection(),
          ),

          // Bottom note
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: KTokens.accentSoft,
              borderRadius: BorderRadius.circular(KTokens.rMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 16, color: KTokens.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu agenda está conectada',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: KTokens.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProximasAgendasSection extends StatelessWidget {
  const _ProximasAgendasSection();

  static const _rows = [
    _AgendaRow(name: 'Lucía Méndez',   time: 'Hoy · 10:00',   confirmed: true),
    _AgendaRow(name: 'Martín Da Silva', time: 'Hoy · 11:50',   confirmed: true),
    _AgendaRow(name: 'Carlo Beñaraux', time: 'Mañana · 09:30', confirmed: false),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _rows.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: KTokens.border),
      itemBuilder: (_, i) => _rows[i],
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.name,
    required this.time,
    required this.confirmed,
  });

  final String name;
  final String time;
  final bool   confirmed;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }

  Color get _color => _palette[name.hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(
                _initials,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KTokens.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: KTokens.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: confirmed
                  ? const Color(0xFF22C55E).withValues(alpha: 0.10)
                  : KTokens.border,
              borderRadius: BorderRadius.circular(KTokens.rPill),
            ),
            child: Text(
              confirmed ? 'Confirmado' : 'Pendiente',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: confirmed
                    ? const Color(0xFF16A34A)
                    : KTokens.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RendimientoNegociosSection extends StatelessWidget {
  const _RendimientoNegociosSection();

  static const _rows = [
    (name: 'Corte de cabello', count: 32),
    (name: 'Coloración',       count: 24),
    (name: 'Manicure',         count: 18),
    (name: 'Barba',            count: 15),
    (name: 'Otros servicios',  count: 8),
  ];

  @override
  Widget build(BuildContext context) {
    final max = _rows.map((r) => r.count).reduce((a, b) => a > b ? a : b);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _rows.length,
      itemBuilder: (_, i) {
        final row = _rows[i];
        final frac = row.count / max;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  row.name,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: KTokens.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(KTokens.rPill),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 5,
                    backgroundColor: KTokens.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      KTokens.accent.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 22,
                child: Text(
                  '${row.count}',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: KTokens.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mobile top bar
                  if (!isWide && onBack != null) ...[
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onBack,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: KTokens.borderStrong),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: KTokens.inkMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'konecta',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: KTokens.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Eyebrow + "Nueva agenda" button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        nombre != null
                            ? 'DASHBOARD · ${nombre!.split(' ').first.toUpperCase()}'
                            : 'DASHBOARD',
                        style: KTokens.tEyebrow,
                      ),
                      const Spacer(),
                      _NewAgendaButton(),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Headline
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Este es el resumen de ',
                          style: GoogleFonts.inter(
                            fontSize: isWide ? 28 : 22,
                            fontWeight: FontWeight.w700,
                            color: KTokens.ink,
                            letterSpacing: -0.5,
                            height: 1.15,
                          ),
                        ),
                        TextSpan(
                          text: 'tu negocio.',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isWide ? 32 : 26,
                            fontStyle: FontStyle.italic,
                            color: KTokens.accent,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Más info de tu agenda y rendimiento de tu negocio.',
                    style: KTokens.tHint,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),

        // ── TUS UBICACIONES carousel ─────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
          sliver: SliverToBoxAdapter(
            child: _SucursalesSection(
              tenantId:           tenantId,
              businesses:         businesses,
              selectedBusinessId: dashboardBusinessId,
              onAdd:              onAdd,
              onTap:              onTap,
              onFilterSelect:     onFilterSelect,
            ),
          ),
        ),

        // ── Dashboard stats ──────────────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
          sliver: SliverToBoxAdapter(
            child: DashboardSection(
              tenantId:   tenantId,
              businesses: businesses,
            ),
          ),
        ),
      ],
    );
  }
}

class _NewAgendaButton extends StatelessWidget {
  const _NewAgendaButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: KTokens.accent,
          borderRadius: BorderRadius.circular(KTokens.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              'Nueva agenda',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sucursales Section ────────────────────────────────────────────────────────

class _SucursalesSection extends StatelessWidget {
  const _SucursalesSection({
    required this.tenantId,
    required this.businesses,
    required this.selectedBusinessId,
    required this.onAdd,
    required this.onTap,
    required this.onFilterSelect,
  });

  final String              tenantId;
  final List<Business>      businesses;
  final String?             selectedBusinessId;
  final VoidCallback        onAdd;
  final void Function(Business) onTap;
  final void Function(Business) onFilterSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TUS UBICACIONES',
              style: KTokens.tEyebrow,
            ),
            const Spacer(),
            Text(
              'Toca para filtrar',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: KTokens.inkSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: businesses.length + 1,
            itemBuilder: (ctx, i) {
              if (i < businesses.length) {
                final b = businesses[i];
                return _BusinessCircle(
                  business:    b,
                  selected:    selectedBusinessId == b.id,
                  onTap:       () => onFilterSelect(b),
                  onLongPress: () => onTap(b),
                );
              }
              return _NewSucursalButton(onTap: onAdd);
            },
          ),
        ),
      ],
    );
  }
}

// ── Business Circle ───────────────────────────────────────────────────────────

class _BusinessCircle extends StatelessWidget {
  const _BusinessCircle({
    required this.business,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final Business     business;
  final bool         selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  int get _idx => business.nombre.hashCode.abs() % _palette.length;
  Color get _color => _palette[_idx];

  String get _initials {
    final words = business.nombre.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return business.nombre
        .substring(0, business.nombre.length.clamp(1, 2))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:       onTap,
      onLongPress: onLongPress,
      behavior:    HitTestBehavior.opaque,
      child: Container(
        width:  90,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                color:  KTokens.surface,
                border: selected
                    ? Border.all(color: KTokens.accent, width: 2.5)
                    : Border.all(color: KTokens.border),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? KTokens.accent.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: selected ? 14 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: business.logoUrl != null
                    ? Image.network(
                        business.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, trace) => _InitialsCircle(
                          initials: _initials,
                          color:    _color,
                        ),
                      )
                    : _InitialsCircle(
                        initials: _initials,
                        color:    _color,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              business.nombre,
              textAlign: TextAlign.center,
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize:   11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color:      selected ? KTokens.accent : KTokens.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── New Sucursal Button ───────────────────────────────────────────────────────

class _NewSucursalButton extends StatelessWidget {
  const _NewSucursalButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width:  90,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KTokens.surface,
                border: Border.all(
                  color: KTokens.accent.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add, size: 26, color: KTokens.accent),
            ),
            const SizedBox(height: 8),
            Text(
              'Agregar',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize:   11,
                fontWeight: FontWeight.w500,
                color:      KTokens.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Initials Circle ───────────────────────────────────────────────────────────

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({required this.initials, required this.color});

  final String initials;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            fontSize:   20,
            fontWeight: FontWeight.w700,
            color:      color,
          ),
        ),
      ),
    );
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
