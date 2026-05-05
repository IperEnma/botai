import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/business.dart';
import '../../../providers/agenda/public/public_categories_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import 'widgets/business_form_dialog.dart';
import 'widgets/category_multi_select_dialog.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _kPrimary    = Color(0xFF6366F1);
const _kText       = Color(0xFF0F172A);
const _kTextSub    = Color(0xFF64748B);
const _kSurface    = Color(0xFFF8FAFC);


const _palette = [
  Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899),
  Color(0xFF14B8A6), Color(0xFF22C55E), Color(0xFFF59E0B),
  Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFF84CC16),
];

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
  bool _socialChanged  = false;
  bool _isSavingSocial = false;
  String? _initBusinessId;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
    final state = ref.watch(businessesProvider(widget.tenantId));

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Mi negocio',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/agenda'),
        ),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, BusinessesState state) {
    if (state.isLoading) return const AgendaLoadingView();
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(businessesProvider(widget.tenantId).notifier).load(),
      );
    }

    final first = state.items.isEmpty ? null : state.items.first;
    if (first != null) _syncControllers(first);

    return CustomScrollView(
      slivers: [
        // ── Sucursales (primer bloque) ────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _SucursalesSection(
              tenantId: widget.tenantId,
              businesses: state.items,
              onAdd: () => _createBusiness(context),
              onTap: (b) => context.push(
                '/agenda/tenants/${widget.tenantId}/businesses/${b.id}',
              ),
            ),
          ),
        ),

        // ── Info + Categorías ──────────────────────────────────────────────
        if (first != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InfoCard(
                      business: first,
                      onEdit: () => _editBusiness(context, first),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CategoriesCard(
                      business: first,
                      tenantId: widget.tenantId,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Social ────────────────────────────────────────────────────────
        if (first != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverToBoxAdapter(
              child: _SocialCard(
                business: first,
                instagramCtrl: _instagramCtrl,
                tiktokCtrl:    _tiktokCtrl,
                facebookCtrl:  _facebookCtrl,
                changed:       _socialChanged,
                saving:        _isSavingSocial,
                onChanged: () {
                  if (!_socialChanged) setState(() => _socialChanged = true);
                },
                onSave: () => _saveSocial(first),
              ),
            ),
          ),
      ],
    );
  }
}

// ── MiniCard base ─────────────────────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.business, required this.onEdit});

  final Business business;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _MiniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Info',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kTextSub,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.edit_outlined, size: 15, color: _kTextSub),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (business.descripcion != null && business.descripcion!.isNotEmpty) ...[
            Text(
              business.descripcion!,
              style: GoogleFonts.poppins(fontSize: 13, color: _kText),
            ),
            const SizedBox(height: 10),
          ],
          if (business.searchTags.isEmpty)
            Text(
              'Sin tags',
              style: GoogleFonts.poppins(fontSize: 12, color: _kTextSub),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in business.searchTags)
                  _Tag(label: tag),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Categories Card ───────────────────────────────────────────────────────────

class _CategoriesCard extends ConsumerWidget {
  const _CategoriesCard({
    required this.business,
    required this.tenantId,
  });

  final Business business;
  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(publicCategoriesProvider);

    return _MiniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Categorías',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kTextSub,
                ),
              ),
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
                  color: _kTextSub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (business.categorias.isEmpty)
            Text(
              'Sin categorías',
              style: GoogleFonts.poppins(fontSize: 12, color: _kTextSub),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final slug in business.categorias)
                  _Tag(
                    label: slug,
                    color: _kPrimary.withValues(alpha: 0.10),
                    textColor: _kPrimary,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Social Card ───────────────────────────────────────────────────────────────

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

  final Business business;
  final TextEditingController instagramCtrl;
  final TextEditingController tiktokCtrl;
  final TextEditingController facebookCtrl;
  final bool changed;
  final bool saving;
  final VoidCallback onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _MiniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Redes sociales',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kTextSub,
            ),
          ),
          const SizedBox(height: 12),
          _SocialRow(
            color: const Color(0xFFE1306C),
            icon: Icons.camera_alt_outlined,
            hint: 'instagram.com/tu-negocio',
            controller: instagramCtrl,
            onChanged: onChanged,
          ),
          const SizedBox(height: 10),
          _SocialRow(
            color: Colors.black87,
            icon: Icons.music_note_outlined,
            hint: 'tiktok.com/@tu-negocio',
            controller: tiktokCtrl,
            onChanged: onChanged,
          ),
          const SizedBox(height: 10),
          _SocialRow(
            color: const Color(0xFF1877F2),
            icon: Icons.facebook_outlined,
            hint: 'facebook.com/tu-negocio',
            controller: facebookCtrl,
            onChanged: onChanged,
          ),
          if (changed) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: saving ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  saving ? 'Guardando…' : 'Guardar',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

  final Color color;
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            style: GoogleFonts.poppins(fontSize: 13, color: _kText),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              hintText: hint,
              hintStyle: GoogleFonts.poppins(fontSize: 12, color: _kTextSub),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _kPrimary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sucursales Section ────────────────────────────────────────────────────────

class _SucursalesSection extends StatelessWidget {
  const _SucursalesSection({
    required this.tenantId,
    required this.businesses,
    required this.onAdd,
    required this.onTap,
  });

  final String tenantId;
  final List<Business> businesses;
  final VoidCallback onAdd;
  final void Function(Business) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sucursales',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: businesses.length + 1,
            itemBuilder: (ctx, i) {
              if (i < businesses.length) {
                return _BusinessCircle(
                  business: businesses[i],
                  onTap: () => onTap(businesses[i]),
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
  const _BusinessCircle({required this.business, required this.onTap});

  final Business business;
  final VoidCallback onTap;

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
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: business.logoUrl != null
                    ? Image.network(
                        business.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => _InitialsCircle(
                          initials: _initials,
                          color: _color,
                        ),
                      )
                    : _InitialsCircle(
                        initials: _initials,
                        color: _color,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              business.nombre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _kText,
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
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: _kPrimary.withValues(alpha: 0.30),
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
              child: const Icon(Icons.add, size: 28, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Nueva',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _kTextSub,
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
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
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
        color: color ?? _kTextSub.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor ?? _kTextSub,
        ),
      ),
    );
  }
}
