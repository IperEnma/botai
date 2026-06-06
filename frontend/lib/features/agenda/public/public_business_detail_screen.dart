import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/business_hours.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/public/public_business_detail_provider.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import 'public_reservar_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen entry points (firmas usadas por el router — no tocar)
// ─────────────────────────────────────────────────────────────────────────────

class PublicBusinessDetailScreen extends ConsumerWidget {
  const PublicBusinessDetailScreen({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(publicBusinessProvider(businessId));
    final servicesAsync = ref.watch(publicBusinessServicesProvider(businessId));

    return businessAsync.when(
      loading: () => const Scaffold(body: AgendaLoadingView()),
      error: (e, _) => Scaffold(
        body: AgendaErrorView(
          message: 'No se pudo cargar el negocio: $e',
          onRetry: () => ref.refresh(publicBusinessProvider(businessId)),
        ),
      ),
      data: (b) => _DetailView(business: b, servicesAsync: servicesAsync),
    );
  }
}

/// Variante que carga todo por `slug` (URL amigable) sin redireccionar a una URL con UUID.
class PublicBusinessDetailBySlugScreen extends ConsumerWidget {
  const PublicBusinessDetailBySlugScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(publicBusinessBySlugProvider(slug));
    final servicesAsync = ref.watch(publicBusinessServicesBySlugProvider(slug));

    return businessAsync.when(
      loading: () => const Scaffold(body: AgendaLoadingView()),
      error: (e, _) => Scaffold(
        body: AgendaErrorView(
          message: 'No se pudo cargar el negocio: $e',
          onRetry: () => ref.refresh(publicBusinessBySlugProvider(slug)),
        ),
      ),
      data: (b) =>
          _DetailView(business: b, servicesAsync: servicesAsync, slug: slug),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full page
// ─────────────────────────────────────────────────────────────────────────────

class _DetailView extends ConsumerWidget {
  const _DetailView({
    required this.business,
    required this.servicesAsync,
    this.slug,
  });

  final Business business;
  final AsyncValue<List<AgendaService>> servicesAsync;
  final String? slug;

  /// Slug efectivo: el de la ruta o el público del negocio. Necesario para reservar.
  String? get _effectiveSlug {
    if (slug != null && slug!.isNotEmpty) return slug;
    final s = business.publicSlug;
    return (s != null && s.isNotEmpty) ? s : null;
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _openBooking(BuildContext context) {
    final target = _effectiveSlug;
    if (target != null) {
      context.go('/reservar/$target');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservá desde el enlace público del negocio.')),
    );
  }

  void _comingSoon(BuildContext context, PublicReservarTheme t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Próximamente', style: t.textStyle(color: Colors.white))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = PublicReservarTheme.fromHex(
      colorPrimario: business.colorPrimario,
      colorFondo: business.colorFondo,
      fontFamily: business.fontFamily,
      logoUrl: business.logoUrl,
    );

    final hasSlug = _effectiveSlug != null;
    final slugForData = _effectiveSlug;

    // Staff y horarios: por slug si está disponible, si no por businessId.
    final staffAsync = hasSlug
        ? ref.watch(publicStaffBySlugProvider(slugForData!))
        : ref.watch(publicStaffProvider(business.id));
    final hoursAsync = hasSlug
        ? ref.watch(publicHoursBySlugProvider(slugForData!))
        : ref.watch(publicHoursProvider(business.id));

    final services = servicesAsync.valueOrNull ?? const <AgendaService>[];
    final canBook = hasSlug && services.isNotEmpty;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    theme: t,
                    business: business,
                    onBack: () => _goBack(context),
                    onShare: () => _comingSoon(context, t),
                  ),
                  const SizedBox(height: 12),
                  _IdentityBlock(theme: t, business: business),
                  const SizedBox(height: 24),
                  _ServicesSection(
                    theme: t,
                    servicesAsync: servicesAsync,
                    showSeeAll: hasSlug,
                    onSeeAll: () => _openBooking(context),
                    onTapService: () => _openBooking(context),
                  ),
                  const SizedBox(height: 28),
                  _HoursSection(theme: t, hoursAsync: hoursAsync),
                  if (business.direccion != null &&
                      business.direccion!.trim().isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _LocationSection(theme: t, direccion: business.direccion!.trim()),
                  ],
                  const SizedBox(height: 28),
                  _TeamSection(theme: t, staffAsync: staffAsync),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BookingCta(
        theme: t,
        enabled: canBook,
        onPressed: canBook ? () => _openBooking(context) : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header (banner + acciones + logo superpuesto)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.theme,
    required this.business,
    required this.onBack,
    required this.onShare,
  });

  final PublicReservarTheme theme;
  final Business business;
  final VoidCallback onBack;
  final VoidCallback onShare;

  static const double _bannerHeight = 200;
  static const double _logoSize = 92;

  bool get _hasBanner =>
      business.bannerUrl != null &&
      business.bannerUrl!.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final t = theme;
    const overhang = _logoSize / 2;

    return SizedBox(
      height: _bannerHeight + overhang,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _bannerHeight,
            child: _Banner(theme: t, hasBanner: _hasBanner, url: business.bannerUrl),
          ),
          // Acciones sobre el banner.
          Positioned(
            top: 12,
            left: 12,
            child: _CircleAction(icon: Icons.arrow_back_ios_new, onTap: onBack),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _CircleAction(icon: Icons.ios_share, onTap: onShare),
                const SizedBox(width: 10),
                const _FavoriteAction(),
              ],
            ),
          ),
          // Logo superpuesto al borde inferior del banner.
          Positioned(
            top: _bannerHeight - overhang,
            left: 0,
            right: 0,
            child: Center(
              child: PublicReservarAvatar(
                nombre: business.nombre,
                logoUrl: business.logoUrl,
                color: t.primary,
                borderColor: t.background,
                initialsColor: t.primary,
                size: _logoSize,
                elevated: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.theme, required this.hasBanner, required this.url});

  final PublicReservarTheme theme;
  final bool hasBanner;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final gradient = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.primaryGradient,
        ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasBanner)
          Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => gradient,
          )
        else
          gradient,
        // Overlay oscuro sutil para legibilidad de los botones.
        Container(color: Colors.black.withValues(alpha: 0.22)),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

/// Botón favorito visual (sin backend): alterna el ícono de corazón localmente.
class _FavoriteAction extends StatefulWidget {
  const _FavoriteAction();

  @override
  State<_FavoriteAction> createState() => _FavoriteActionState();
}

class _FavoriteActionState extends State<_FavoriteAction> {
  bool _fav = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _fav = !_fav),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            _fav ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nombre + rating + categorías
// ─────────────────────────────────────────────────────────────────────────────

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({required this.theme, required this.business});

  final PublicReservarTheme theme;
  final Business business;

  bool get _showRating =>
      business.reviewCount > 0 && business.rating != null;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            business.nombre,
            textAlign: TextAlign.center,
            style: t.textStyle(size: 24, weight: FontWeight.w700),
          ),
          if (_showRating) ...[
            const SizedBox(height: 8),
            _RatingRow(
              theme: t,
              rating: business.rating!,
              reviewCount: business.reviewCount,
            ),
          ],
          if (business.descripcion != null &&
              business.descripcion!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              business.descripcion!.trim(),
              textAlign: TextAlign.center,
              style: t.textStyle(size: 14, color: t.textSub),
            ),
          ],
          if (business.categorias.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final cat in business.categorias.take(6))
                  _CategoryPill(theme: t, label: cat),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.theme,
    required this.rating,
    required this.reviewCount,
  });

  final PublicReservarTheme theme;
  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final label =
        '${rating.toStringAsFixed(1)} ($reviewCount ${reviewCount == 1 ? 'reseña' : 'reseñas'})';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Stars(theme: t, rating: rating, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: t.textStyle(size: 14, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.theme, required this.rating, this.size = 16});

  final PublicReservarTheme theme;
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final empty = t.primary.withValues(alpha: 0.25);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final pos = i + 1;
        if (rating >= pos) {
          return Icon(Icons.star_rounded, size: size, color: t.primary);
        }
        if (rating >= pos - 0.5) {
          return Icon(Icons.star_half_rounded, size: size, color: t.primary);
        }
        return Icon(Icons.star_rounded, size: size, color: empty);
      }),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.theme, required this.label});

  final PublicReservarTheme theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: t.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: t.textStyle(size: 12, weight: FontWeight.w600, color: t.primary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header reutilizable (título + link opcional)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.theme,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final PublicReservarTheme theme;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: t.textStyle(size: 18, weight: FontWeight.w700),
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: t.textStyle(
                      size: 13,
                      weight: FontWeight.w600,
                      color: t.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: t.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Servicios
// ─────────────────────────────────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({
    required this.theme,
    required this.servicesAsync,
    required this.showSeeAll,
    required this.onSeeAll,
    required this.onTapService,
  });

  final PublicReservarTheme theme;
  final AsyncValue<List<AgendaService>> servicesAsync;
  final bool showSeeAll;
  final VoidCallback onSeeAll;
  final VoidCallback onTapService;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionHeader(
            theme: t,
            title: 'Servicios',
            actionLabel: showSeeAll ? 'Ver todos' : null,
            onAction: showSeeAll ? onSeeAll : null,
          ),
        ),
        const SizedBox(height: 14),
        servicesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'No se pudieron cargar los servicios.',
              style: t.textStyle(size: 14, color: t.textSub),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Este negocio todavía no publicó servicios.',
                  style: t.textStyle(size: 14, color: t.textSub),
                ),
              );
            }
            return SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _ServiceCard(
                  theme: t,
                  service: list[i],
                  onTap: onTapService,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.theme,
    required this.service,
    required this.onTap,
  });

  final PublicReservarTheme theme;
  final AgendaService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return SizedBox(
      width: 200,
      child: Material(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: t.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: t.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.spa_outlined, color: t.primary, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  service.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.textStyle(size: 15, weight: FontWeight.w600),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: t.textSub),
                    const SizedBox(width: 4),
                    Text(
                      '${service.duracionMin} min',
                      style: t.textStyle(size: 12, color: t.textSub),
                    ),
                    const Spacer(),
                    Text(
                      '\$${service.precio.toStringAsFixed(0)}',
                      style: t.textStyle(
                        size: 16,
                        weight: FontWeight.w700,
                        color: t.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horarios de atención
// ─────────────────────────────────────────────────────────────────────────────

class _HoursSection extends StatelessWidget {
  const _HoursSection({required this.theme, required this.hoursAsync});

  final PublicReservarTheme theme;
  final AsyncValue<List<BusinessHours>> hoursAsync;

  static const _shortDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String _label(BusinessHours? row) {
    if (row == null || row.cerrado) return 'Cerrado';
    final ranges = <String>[];
    bool has(String? a, String? c) =>
        a != null && a.isNotEmpty && c != null && c.isNotEmpty;
    if (has(row.apertura, row.cierre)) {
      ranges.add('${row.apertura} – ${row.cierre}');
    }
    if (has(row.apertura2, row.cierre2)) {
      ranges.add('${row.apertura2} – ${row.cierre2}');
    }
    return ranges.isEmpty ? 'Cerrado' : ranges.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(theme: t, title: 'Horarios de atención'),
          const SizedBox(height: 14),
          hoursAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(
              'No se pudieron cargar los horarios.',
              style: t.textStyle(size: 14, color: t.textSub),
            ),
            data: (hours) {
              if (hours.isEmpty) {
                return Text(
                  'Este negocio todavía no publicó sus horarios.',
                  style: t.textStyle(size: 14, color: t.textSub),
                );
              }
              final todayDow = DateTime.now().weekday - 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.cardBorder),
                ),
                child: Column(
                  children: [
                    for (var dow = 0; dow < 7; dow++)
                      _HoursRow(
                        theme: t,
                        day: _shortDays[dow],
                        value: _label(_rowFor(hours, dow)),
                        highlight: dow == todayDow,
                        showDivider: dow < 6,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  BusinessHours? _rowFor(List<BusinessHours> hours, int dow) {
    for (final h in hours) {
      if (h.diaSemana == dow) return h;
    }
    return null;
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow({
    required this.theme,
    required this.day,
    required this.value,
    required this.highlight,
    required this.showDivider,
  });

  final PublicReservarTheme theme;
  final String day;
  final String value;
  final bool highlight;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final weight = highlight ? FontWeight.w700 : FontWeight.w500;
    final color = highlight ? t.primary : t.text;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  day,
                  style: t.textStyle(size: 14, weight: weight, color: color),
                ),
              ),
              Text(
                value,
                textAlign: TextAlign.right,
                style: t.textStyle(
                  size: 14,
                  weight: highlight ? FontWeight.w600 : FontWeight.w500,
                  color: highlight ? t.primary : t.textSub,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: t.cardBorder),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ubicación (sin mapa interactivo; url_launcher no disponible → solo dirección)
// ─────────────────────────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.theme, required this.direccion});

  final PublicReservarTheme theme;
  final String direccion;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(theme: t, title: 'Ubicación'),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Thumbnail tipo mapa (placeholder estático).
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        t.primary.withValues(alpha: 0.18),
                        t.primary.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.location_on, color: t.primary, size: 28),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.place_outlined, size: 20, color: t.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          direccion,
                          style: t.textStyle(size: 14, weight: FontWeight.w500),
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Equipo
// ─────────────────────────────────────────────────────────────────────────────

class _TeamSection extends StatelessWidget {
  const _TeamSection({required this.theme, required this.staffAsync});

  final PublicReservarTheme theme;
  final AsyncValue<List<StaffMember>> staffAsync;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return staffAsync.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (staff) {
        final activos = staff.where((s) => s.activo).toList(growable: false);
        if (activos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(theme: t, title: 'Equipo'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: activos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    _StaffCard(theme: t, staff: activos[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.theme, required this.staff});

  final PublicReservarTheme theme;
  final StaffMember staff;

  bool get _showRating => staff.reviewCount > 0 && staff.rating != null;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return SizedBox(
      width: 140,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder),
        ),
        child: Column(
          children: [
            PublicReservarAvatar(
              nombre: staff.nombre,
              logoUrl: staff.avatarUrl,
              color: t.primary,
              initialsColor: t.primary,
              size: 56,
            ),
            const SizedBox(height: 10),
            Text(
              staff.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: t.textStyle(size: 14, weight: FontWeight.w600),
            ),
            if (staff.rol != null && staff.rol!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                staff.rol!.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: t.textStyle(size: 12, color: t.textSub),
              ),
            ],
            if (_showRating) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, size: 15, color: t.primary),
                  const SizedBox(width: 3),
                  Text(
                    staff.rating!.toStringAsFixed(1),
                    style: t.textStyle(size: 12, weight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA fijo
// ─────────────────────────────────────────────────────────────────────────────

class _BookingCta extends StatelessWidget {
  const _BookingCta({
    required this.theme,
    required this.enabled,
    required this.onPressed,
  });

  final PublicReservarTheme theme;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: t.primary,
                disabledBackgroundColor: t.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
              label: Text(
                enabled ? 'Reservar turno' : 'Reservá desde el enlace del negocio',
                style: t.textStyle(
                  size: 15,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
