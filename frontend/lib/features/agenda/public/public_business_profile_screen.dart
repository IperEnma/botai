import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/agenda_address.dart';
import '../../../core/agenda_icon_registry.dart';
import '../../../core/business_hours_summary.dart';
import '../../../core/business_open_status.dart';
import '../../../core/agenda_media_image.dart';
import '../../../core/agenda_media_url.dart';
import '../../../core/google_maps_urls.dart';
import '../../../core/openstreetmap_preview.dart';
import '../../../core/open_external_url.dart';
import '../../../core/public_business_share.dart';
import '../../../providers/agenda/public/public_client_session_provider.dart';
import '../../../providers/agenda/public/public_favorites_provider.dart';
import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/business_hours.dart';
import '../../../models/agenda/business_photo.dart';
import '../../../models/agenda/category.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../providers/agenda/public/public_categories_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import 'public_phone_verify_sheet.dart';
import 'public_reservar_layout.dart';
import 'public_service_booking_modal.dart';

/// Perfil público del negocio — diseño mockup Felito Barber.
/// Ruta: `/reservar/:slug`
class PublicBusinessProfileScreen extends ConsumerWidget {
  const PublicBusinessProfileScreen({super.key, required this.slug});

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
      data: (business) => _FelitoBarberPage(
        business: business,
        servicesAsync: servicesAsync,
        slug: slug,
      ),
    );
  }
}

// ─── Tema del negocio (colorPrimario / colorFondo del dueño) ─────────────────

class _PublicProfileScope extends InheritedWidget {
  const _PublicProfileScope({required this.theme, required super.child});

  final PublicReservarTheme theme;

  static PublicReservarTheme of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_PublicProfileScope>()!
        .theme;
  }

  @override
  bool updateShouldNotify(_PublicProfileScope oldWidget) =>
      theme.primary != oldWidget.theme.primary ||
      theme.background != oldWidget.theme.background ||
      theme.card != oldWidget.theme.card;
}

// ─── Design tokens (layout fijo; acento = tema del negocio) ───────────────────

abstract final class _D {
  static Color brand(BuildContext context) =>
      _PublicProfileScope.of(context).primary;

  static Color pageBg(BuildContext context) =>
      _PublicProfileScope.of(context).background;

  static Color card(BuildContext context) =>
      _PublicProfileScope.of(context).card;

  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const faint = Color(0xFF9CA3AF);
  static const white = Colors.white;
  static const shadow = Color(0x12000000);

  static const pad = 16.0;
  static const r = 16.0;
  /// Altura mínima/máxima del banner (el valor real es % de pantalla en el hero).
  static const bannerMinH = 220.0;
  static const bannerMaxH = 320.0;
  static const logo = 96.0;
  static const logoBorder = 4.0;
  /// Margen inferior del bloque logo + texto dentro del banner.
  static const bannerIdentityBottom = 20.0;

  static TextStyle t(
    double s, {
    FontWeight w = FontWeight.w400,
    Color c = ink,
    double? h,
  }) =>
      GoogleFonts.inter(fontSize: s, fontWeight: w, color: c, height: h);
}

bool _isWideProfile(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= _kWideBreakpoint;

const _kWideBreakpoint = 900.0;
const _kContentMaxWidth = 1140.0;
const _kSidebarWidth = 340.0;

/// Mismo ancho y márgenes que el cuerpo del perfil (hero alineado con secciones).
class _ProfileContentAlign extends StatelessWidget {
  const _ProfileContentAlign({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: _D.pad),
      child: child,
    );
    if (!_isWideProfile(context)) return padded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _D.pad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
          child: child,
        ),
      ),
    );
  }
}

// ─── Page ────────────────────────────────────────────────────────────────────

class _FelitoBarberPage extends ConsumerWidget {
  const _FelitoBarberPage({
    required this.business,
    required this.servicesAsync,
    required this.slug,
  });

  final Business business;
  final AsyncValue<List<AgendaService>> servicesAsync;
  final String slug;

  void _back(BuildContext c) => c.canPop() ? c.pop() : c.go('/');

  void _openBookingModal(BuildContext context, {AgendaService? service}) {
    showPublicServiceBookingModal(
      context: context,
      slug: slug,
      business: business,
      initialService: service,
    );
  }

  void _openWorksGallery(BuildContext context, List<BusinessPhoto> photos) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _D.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_D.r)),
      ),
      builder: (ctx) => _WorksGallerySheet(photos: photos),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(publicStaffBySlugProvider(slug));
    final hours = ref.watch(publicHoursBySlugProvider(slug));
    final photos = ref.watch(publicPhotosBySlugProvider(slug));
    final services = servicesAsync.valueOrNull ?? const [];
    final canBook = services.isNotEmpty;
    final addr = resolveBusinessAddress(business) ?? '';
    final theme = PublicReservarTheme.fromHex(
      colorPrimario: business.colorPrimario,
      colorFondo: business.colorFondo,
      colorTarjeta: business.colorTarjeta,
      fontFamily: business.fontFamily,
      logoUrl: business.logoUrl,
    );

    final wide = _isWideProfile(context);
    final bottomPad = wide
        ? 24.0 + MediaQuery.paddingOf(context).bottom
        : 88.0 + MediaQuery.paddingOf(context).bottom;

    return _PublicProfileScope(
      theme: theme,
      child: Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  business: business,
                  slug: slug,
                  onBack: () => _back(context),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  _D.pad,
                  14,
                  _D.pad,
                  bottomPad,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kContentMaxWidth,
                      ),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRect(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _Services(
                                          servicesAsync: servicesAsync,
                                          categorySlugs: business.categorias,
                                          useGrid: true,
                                          onAll: () =>
                                              _openBookingModal(context),
                                          onPick: (svc) => _openBookingModal(
                                            context,
                                            service: svc,
                                          ),
                                        ),
                                        const SizedBox(height: 26),
                                        _Team(staffAsync: staff),
                                        _Works(
                                          photosAsync: photos,
                                          onViewAll: (all) =>
                                              _openWorksGallery(context, all),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                SizedBox(
                                  width: _kSidebarWidth,
                                  child: _Location(
                                    business: business,
                                    address: addr,
                                    hoursAsync: hours,
                                    sidebar: true,
                                    onBook: canBook
                                        ? () => _openBookingModal(context)
                                        : null,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Services(
                                  servicesAsync: servicesAsync,
                                  categorySlugs: business.categorias,
                                  onAll: () => _openBookingModal(context),
                                  onPick: (svc) => _openBookingModal(
                                    context,
                                    service: svc,
                                  ),
                                ),
                                const SizedBox(height: 26),
                                _Location(
                                  business: business,
                                  address: addr,
                                  hoursAsync: hours,
                                ),
                                const SizedBox(height: 26),
                                _Team(staffAsync: staff),
                                _Works(
                                  photosAsync: photos,
                                  onViewAll: (all) =>
                                      _openWorksGallery(context, all),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!wide)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomCta(
                enabled: canBook,
                onTap: canBook ? () => _openBookingModal(context) : null,
              ),
            ),
        ],
      ),
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _Hero extends ConsumerWidget {
  const _Hero({
    required this.business,
    required this.slug,
    required this.onBack,
  });

  final Business business;
  final String slug;
  final VoidCallback onBack;

  List<String> _heroPills(List<Category>? catalog) {
    final pills = <String>[];
    final seen = <String>{};

    void add(String label) {
      final t = label.trim();
      if (t.isEmpty) return;
      final key = t.toLowerCase();
      if (seen.contains(key)) return;
      seen.add(key);
      pills.add(t);
    }

    for (final value in business.categorias.take(3)) {
      if (catalog != null) {
        var matched = false;
        for (final c in catalog) {
          if (c.slug == value || c.nombre == value) {
            add(c.nombre);
            matched = true;
            break;
          }
        }
        if (!matched) add(_prettyCat(value));
      } else {
        add(_prettyCat(value));
      }
    }

    for (final tag in business.profileTagLabels) {
      if (pills.length >= 3) break;
      add(tag);
    }

    return pills.take(3).toList();
  }

  String get _ratingLabel {
    if (business.reviewCount > 0 && business.rating != null) {
      return '${business.rating!.toStringAsFixed(1)} (${business.reviewCount} reseñas)';
    }
    return 'Sin reseñas aún';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(publicCategoriesProvider).valueOrNull;
    final top = MediaQuery.paddingOf(context).top;
    final bannerH = (MediaQuery.sizeOf(context).height * 0.36)
        .clamp(_D.bannerMinH, _D.bannerMaxH);
    final hasBanner = isAgendaMediaUrl(business.bannerUrl);
    final cats = _heroPills(catalog);
    final bannerBottom = top + bannerH;

    return SizedBox(
      height: bannerBottom,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Banner a sangre (logo + texto van encima, sin franja blanca) ──
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasBanner)
                  Positioned.fill(
                    child: AgendaMediaImage(
                      url: business.bannerUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      expand: true,
                      errorWidget: const _BannerFallback(),
                    ),
                  )
                else
                  const Positioned.fill(child: _BannerFallback()),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: bannerH * 0.88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                        stops: const [0, 0.4, 0.72, 1],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Logo + texto sobre el banner (referencia Felito Barber) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: _D.bannerIdentityBottom,
            child: _ProfileContentAlign(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _LogoCircle(name: business.nombre, url: business.logoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          business.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _D.t(
                            21,
                            w: FontWeight.w700,
                            c: _D.white,
                            h: 1.12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _Stars(rating: business.rating ?? 0, onDark: true),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _ratingLabel,
                                style: _D.t(
                                  12.5,
                                  w: FontWeight.w500,
                                  c: _D.white.withValues(alpha: 0.95),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        _OpenStatusOnBanner(slug: slug),
                        if (cats.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final c in cats) _Pill(c),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Botones superiores ──
          Positioned(
            top: top + 8,
            left: 0,
            right: 0,
            child: _ProfileContentAlign(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundBtn(
                    icon: Icons.arrow_back_ios_new,
                    size: 16,
                    onTap: onBack,
                  ),
                  Row(
                    children: [
                      Builder(
                        builder: (btnContext) => _RoundBtn(
                          icon: Icons.ios_share,
                          onTap: () => sharePublicBusinessProfile(
                            context: context,
                            slug: slug,
                            businessName: business.nombre,
                            sharePositionOrigin:
                                sharePositionOriginFor(btnContext),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _HeartBtn(slug: slug, business: business),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _prettyCat(String s) {
    return s.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }
}

class _OpenStatusOnBanner extends ConsumerWidget {
  const _OpenStatusOnBanner({required this.slug});

  final String slug;

  static const _openAccent = Color(0xFF86EFAC);
  static const _closedAccent = Color(0xFFFECACA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoursAsync = ref.watch(publicHoursBySlugProvider(slug));
    return hoursAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (hours) {
        final status = BusinessOpenStatus.fromHours(hours);
        if (status == null) return const SizedBox.shrink();

        final accent = status.isOpen ? _openAccent : _closedAccent;
        final detailColor = _D.white.withValues(alpha: 0.72);

        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 0.5),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: status.headline,
                        style: _D.t(
                          11,
                          w: FontWeight.w600,
                          c: accent,
                          h: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: ' · ${status.detail}',
                        style: _D.t(
                          11,
                          w: FontWeight.w400,
                          c: detailColor,
                          h: 1.2,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, this.size = 18, required this.onTap});

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _D.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: size, color: _D.ink),
        ),
      ),
    );
  }
}

class _HeartBtn extends ConsumerStatefulWidget {
  const _HeartBtn({required this.slug, required this.business});

  final String slug;
  final Business business;

  @override
  ConsumerState<_HeartBtn> createState() => _HeartBtnState();
}

class _HeartBtnState extends ConsumerState<_HeartBtn> {
  bool _on = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refreshFavorite();
  }

  Future<void> _refreshFavorite() async {
    final session = await ref.read(publicClientSessionProvider(widget.slug).future);
    if (session == null || session.isExpired) {
      if (mounted) {
        setState(() {
          _on = false;
          _loaded = true;
        });
      }
      return;
    }
    final fav = await ref.read(publicFavoritesStorageProvider).isFavorite(
          phone: session.phone,
          slug: widget.slug,
        );
    if (mounted) {
      setState(() {
        _on = fav;
        _loaded = true;
      });
    }
  }

  Future<void> _toggle() async {
    var session = await ref.read(publicClientSessionProvider(widget.slug).future);
    if (session == null || session.isExpired) {
      if (!mounted) return;
      final ok = await showPublicPhoneVerifySheet(
        context: context,
        business: widget.business,
        slug: widget.slug,
      );
      if (ok != true || !mounted) return;
      session = await ref.read(publicClientSessionProvider(widget.slug).future);
    }
    if (session == null || session.isExpired) return;

    final nowFavorite = await ref.read(publicFavoritesStorageProvider).toggle(
          phone: session.phone,
          slug: widget.slug,
        );
    if (!mounted) return;
    setState(() => _on = nowFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowFavorite ? 'Agregado a favoritos' : 'Quitado de favoritos'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(publicClientSessionProvider(widget.slug), (previous, next) {
      _refreshFavorite();
    });

    return _RoundBtn(
      icon: _on ? Icons.favorite : Icons.favorite_border,
      onTap: _loaded ? _toggle : () {},
    );
  }
}

class _LogoCircle extends StatelessWidget {
  const _LogoCircle({required this.name, required this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _D.logo,
      height: _D.logo,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _D.white,
        border: Border.all(color: _D.white, width: _D.logoBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? AgendaMediaImage(
              url: url,
              fit: BoxFit.cover,
              width: _D.logo,
              height: _D.logo,
              errorWidget: _fb(),
            )
          : _fb(),
    );
  }

  Widget _fb() {
    final w = name.trim().split(RegExp(r'\s+'));
    final l = w.length >= 2
        ? '${w[0][0]}${w[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(1, 2)).toUpperCase();
    return ColoredBox(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Text(l, style: _D.t(22, w: FontWeight.w800, c: _D.white)),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.onDark = false});

  final double rating;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final brand = _D.brand(context);
    final filled = brand;
    final empty = onDark
        ? _D.white.withValues(alpha: 0.35)
        : _D.faint;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final n = i + 1;
        return Icon(
          rating >= n - 0.25 ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: rating >= n - 0.25 ? filled : empty,
        );
      }),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final brand = _D.brand(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _D.white.withValues(alpha: 0.15)),
      ),
      child: Text(label, style: _D.t(11, w: FontWeight.w600, c: _D.white)),
    );
  }
}

// ─── Shared ──────────────────────────────────────────────────────────────────

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, this.link, this.onLink});

  final String title;
  final String? link;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: _D.t(17, w: FontWeight.w700))),
        if (link != null && onLink != null)
          GestureDetector(
            onTap: onLink,
            child: Text('$link >', style: _D.t(13, w: FontWeight.w600, c: _D.brand(context))),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.pad = 16});

  final Widget child;
  final double pad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: _surfaceDecoration(context),
      child: child,
    );
  }
}

/// Cuadrado redondeado con el color primario del negocio (mismo lenguaje que íconos de servicio).
class _BrandSquare extends StatelessWidget {
  const _BrandSquare({
    required this.child,
    this.size = 40,
  });

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _D.brand(context),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );
  }
}

BoxDecoration _surfaceDecoration(BuildContext context) => BoxDecoration(
      color: _D.card(context),
      borderRadius: BorderRadius.circular(_D.r),
      boxShadow: const [
        BoxShadow(color: _D.shadow, blurRadius: 14, offset: Offset(0, 4)),
      ],
    );

// ─── Servicios ───────────────────────────────────────────────────────────────

class _Services extends StatelessWidget {
  const _Services({
    required this.servicesAsync,
    required this.categorySlugs,
    required this.onAll,
    required this.onPick,
    this.useGrid = false,
  });

  final AsyncValue<List<AgendaService>> servicesAsync;
  final List<String> categorySlugs;
  final VoidCallback onAll;
  final ValueChanged<AgendaService> onPick;
  final bool useGrid;

  static const _gridGap = 12.0;
  static const _gridCols = 2;
  static const _gridPreviewLimit = 4;
  static const _cardH = 150.0;

  Widget _serviceCard(AgendaService svc, {double width = 165}) {
    return _ServiceCard(
      svc: svc,
      width: width,
      icon: AgendaIconRegistry.forService(
        svc.nombre,
        categorySlugs: categorySlugs,
      ),
      onTap: () => onPick(svc),
    );
  }

  Widget _sectionHead({required bool showVerTodos}) {
    return _SectionHead(
      title: 'Servicios',
      link: showVerTodos ? 'Ver todos' : null,
      onLink: showVerTodos ? onAll : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        servicesAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHead(showVerTodos: !useGrid),
              const SizedBox(height: 14),
              SizedBox(
                height: _cardH,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _D.brand(context),
                  ),
                ),
              ),
            ],
          ),
          error: (_, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHead(showVerTodos: !useGrid),
              const SizedBox(height: 14),
              Text(
                'Error al cargar servicios.',
                style: _D.t(14, c: _D.muted),
              ),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHead(showVerTodos: false),
                  const SizedBox(height: 14),
                  Text('Sin servicios.', style: _D.t(14, c: _D.muted)),
                ],
              );
            }
            final hasMore = useGrid && list.length > _gridPreviewLimit;
            final visible = useGrid
                ? list.take(_gridPreviewLimit).toList()
                : list;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHead(showVerTodos: useGrid ? hasMore : true),
                const SizedBox(height: 14),
                if (useGrid)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cellW = (constraints.maxWidth -
                              _gridGap * (_gridCols - 1)) /
                          _gridCols;
                      return Wrap(
                        spacing: _gridGap,
                        runSpacing: _gridGap,
                        children: [
                          for (final svc in visible)
                            SizedBox(
                              width: cellW,
                              height: _cardH,
                              child: _serviceCard(svc, width: cellW),
                            ),
                        ],
                      );
                    },
                  )
                else
                  SizedBox(
                    height: _cardH,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.hardEdge,
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _serviceCard(visible[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.svc,
    required this.icon,
    required this.onTap,
    this.width = 165,
  });

  final AgendaService svc;
  final IconData icon;
  final VoidCallback onTap;
  final double width;

  String get _price {
    final n = svc.precio.round();
    final s = n.toString();
    final b = StringBuffer('\$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 150,
      child: Material(
        color: _D.card(context),
        borderRadius: BorderRadius.circular(_D.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_D.r),
          child: Ink(
            decoration: BoxDecoration(
              color: _D.card(context),
              borderRadius: BorderRadius.circular(_D.r),
              boxShadow: const [
                BoxShadow(color: _D.shadow, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandSquare(
                  child: Icon(icon, color: _D.white, size: 20),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    svc.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _D.t(14, w: FontWeight.w700, h: 1.2),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: _D.faint),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${svc.duracionMin} min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _D.t(12, c: _D.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _D.t(15, w: FontWeight.w700, c: _D.brand(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Datos del local (ubicación + horarios) ──────────────────────────────────

class _Location extends StatelessWidget {
  const _Location({
    required this.business,
    required this.address,
    required this.hoursAsync,
    this.sidebar = false,
    this.onBook,
  });

  final Business business;
  final String address;
  final AsyncValue<List<BusinessHours>> hoursAsync;
  final bool sidebar;
  final VoidCallback? onBook;

  bool get _hasAddress => address.trim().isNotEmpty;

  static (String, String?) _addressLines(String addr, Business b) {
    final trimmed = addr.trim();
    if (trimmed.isEmpty) return ('', null);

    final locTags = b.locationTags
        .map((t) => t.value.trim())
        .where((v) => v.isNotEmpty)
        .toList();

    final segments = trimmed
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final digitIdx = segments.indexWhere((s) => RegExp(r'\d').hasMatch(s));
    String line1;
    String? line2;

    if (digitIdx >= 0) {
      line1 = segments[digitIdx];
      if (locTags.isNotEmpty) {
        line2 = locTags.join(', ');
      } else if (digitIdx > 0) {
        line2 = segments.sublist(0, digitIdx).join(', ');
      } else if (digitIdx + 1 < segments.length) {
        line2 = segments.sublist(digitIdx + 1).join(', ');
      }
    } else if (segments.length >= 2) {
      line1 = segments.last;
      line2 = locTags.isNotEmpty
          ? locTags.join(', ')
          : segments.sublist(0, segments.length - 1).join(', ');
    } else {
      line1 = trimmed;
      if (locTags.isNotEmpty) line2 = locTags.join(', ');
    }

    if (line2 != null &&
        line2.trim().toLowerCase() == line1.trim().toLowerCase()) {
      line2 = null;
    }

    return (line1, line2);
  }

  static String _geocodeQuery(String addr, Business b) {
    return OpenStreetMapPreview.geocodeQuery(
      address: addr,
      locationHints: b.locationTags.map((t) => t.value),
    );
  }

  String get _sectionTitle => sidebar ? 'Ubicación' : 'Datos del local';

  Widget _addressText(
    BuildContext context, {
    required String line1,
    required String? line2,
    required String addr,
    required String? mapsUrl,
    bool stacked = false,
  }) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          line1,
          maxLines: stacked ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: _D.t(
            stacked ? 15 : 13,
            w: FontWeight.w600,
            h: 1.35,
          ),
        ),
        if (line2 != null && line2.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            line2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _D.t(13, w: FontWeight.w400, c: _D.muted, h: 1.35),
          ),
        ],
        if (mapsUrl != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => openExternalUrl(mapsUrl),
            child: Text(
              'Ver en el mapa >',
              style: _D.t(13, w: FontWeight.w600, c: _D.brand(context)),
            ),
          ),
        ],
        if (AgendaAddressFormat.looksLikeAreaOnly(addr))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Ubicación aproximada en el mapa.',
              style: _D.t(11, c: _D.muted, h: 1.35),
            ),
          ),
      ],
    );

    if (stacked) return body;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandSquare(
          child: const Icon(
            Icons.place_outlined,
            size: 20,
            color: _D.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: body),
      ],
    );
  }

  Widget? _sidebarBookButton(BuildContext context) {
    final onTap = onBook;
    if (!sidebar || onTap == null) return null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: _D.brand(context),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.calendar_month_outlined, color: _D.white, size: 20),
        label: Text(
          'Reservar turno',
          style: _D.t(15, w: FontWeight.w700, c: _D.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookButton = _sidebarBookButton(context);

    if (!_hasAddress) {
      return hoursAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (rows) {
          final lines = BusinessHoursSummary.lines(rows);
          if (lines.isEmpty && bookButton == null) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHead(title: _sectionTitle),
              const SizedBox(height: 14),
              _Card(
                pad: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lines.isNotEmpty) _HoursSummaryLines(lines: lines),
                    if (bookButton != null) ...[
                      if (lines.isNotEmpty) const SizedBox(height: 16),
                      bookButton,
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    final addr = address.trim();
    final mapsUrl = GoogleMapsUrls.search(addr);
    final (line1, line2) = _addressLines(addr, business);
    final geocodeQuery = _geocodeQuery(addr, business);

    if (sidebar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHead(title: _sectionTitle),
          const SizedBox(height: 14),
          _Card(
            pad: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LayoutBuilder(
                    builder: (context, constraints) => _MapPreview(
                      geocodeQuery: geocodeQuery,
                      mapsUrl: mapsUrl,
                      width: constraints.maxWidth,
                      height: 128,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _addressText(
                  context,
                  line1: line1,
                  line2: line2,
                  addr: addr,
                  mapsUrl: mapsUrl,
                ),
                _EmbeddedHoursSummary(hoursAsync: hoursAsync),
                if (bookButton != null) ...[
                  const SizedBox(height: 16),
                  bookButton,
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(title: _sectionTitle),
        const SizedBox(height: 14),
        _Card(
          pad: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LayoutBuilder(
                  builder: (context, constraints) => _MapPreview(
                    geocodeQuery: geocodeQuery,
                    mapsUrl: mapsUrl,
                    width: constraints.maxWidth,
                    height: 120,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _addressText(
                context,
                line1: line1,
                line2: line2,
                addr: addr,
                mapsUrl: mapsUrl,
                stacked: true,
              ),
              _EmbeddedHoursSummary(hoursAsync: hoursAsync),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmbeddedHoursSummary extends StatelessWidget {
  const _EmbeddedHoursSummary({required this.hoursAsync});

  final AsyncValue<List<BusinessHours>> hoursAsync;

  @override
  Widget build(BuildContext context) {
    return hoursAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _D.brand(context),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (rows) {
        final lines = BusinessHoursSummary.lines(rows);
        if (lines.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(height: 1, color: _D.faint.withValues(alpha: 0.35)),
              const SizedBox(height: 12),
              _HoursSummaryLines(lines: lines),
            ],
          ),
        );
      },
    );
  }
}

class _HoursSummaryLines extends StatelessWidget {
  const _HoursSummaryLines({required this.lines});

  final List<BusinessHoursSummaryLine> lines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandSquare(
          child: const Icon(
            Icons.schedule_outlined,
            size: 20,
            color: _D.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    line.text,
                    style: _D.t(
                      13,
                      w: FontWeight.w500,
                      c: line.isClosed ? _D.faint : _D.muted,
                      h: 1.35,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.geocodeQuery,
    required this.mapsUrl,
    this.width = 96,
    this.height = 96,
  });

  final String geocodeQuery;
  final String? mapsUrl;
  final double width;
  final double height;

  String? get _openUrl {
    final q = geocodeQuery.trim();
    if (q.isEmpty) return null;
    return mapsUrl ?? GoogleMapsUrls.search(q);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE7E4DC),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _MapGridPainter()),
          Center(
            child: Icon(
              Icons.location_on_rounded,
              size: 28,
              color: _D.brand(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = geocodeQuery.trim();
    final openUrl = _openUrl;
    final placeholder = _placeholder(context);

    Widget body;
    if (q.isEmpty) {
      body = placeholder;
    } else {
      final imageUrl = OpenStreetMapPreview.previewImageUrl(
        q,
        pixelSize: (width * 2).round(),
      );
      body = Stack(
        clipBehavior: Clip.none,
        children: [
          Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : placeholder,
            errorBuilder: (_, _, _) => placeholder,
          ),
          Positioned(
            left: 4,
            bottom: 2,
            child: Text(
              '© OSM',
              style: TextStyle(
                fontSize: 7,
                height: 1,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      );
    }

    final sized = SizedBox(width: width, height: height, child: body);
    if (openUrl == null) return sized;

    return GestureDetector(
      onTap: () => openExternalUrl(openUrl),
      child: sized,
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 0.5;
    const step = 16.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Trabajos ────────────────────────────────────────────────────────────────

bool _isValidWorkPhotoUrl(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return false;
  if (isAgendaMediaUrl(t)) return true;
  return t.startsWith('http://') || t.startsWith('https://');
}

List<BusinessPhoto> _visibleWorkPhotos(List<BusinessPhoto> photos) {
  final list = photos.where((p) => _isValidWorkPhotoUrl(p.url)).toList();
  list.sort((a, b) => a.orden.compareTo(b.orden));
  return list;
}

class _Works extends StatelessWidget {
  const _Works({
    required this.photosAsync,
    required this.onViewAll,
  });

  static const _previewLimit = 6;
  static const _maxThumbSize = 100.0;
  static const _gap = 8.0;

  final AsyncValue<List<BusinessPhoto>> photosAsync;
  final ValueChanged<List<BusinessPhoto>> onViewAll;

  @override
  Widget build(BuildContext context) {
    return photosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, s) => const SizedBox.shrink(),
      data: (raw) {
        final photos = _visibleWorkPhotos(raw);
        if (photos.isEmpty) return const SizedBox.shrink();

        final preview = photos.take(_previewLimit).toList();
        final hasMore = photos.length > preview.length;

        return Padding(
          padding: const EdgeInsets.only(top: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHead(
                title: 'Algunos trabajos',
                link: hasMore ? 'Ver todos' : null,
                onLink: hasMore ? () => onViewAll(photos) : null,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 520 ? 4 : 3;
                  final cell = math.min(
                    _maxThumbSize,
                    (constraints.maxWidth - _gap * (cols - 1)) / cols,
                  );
                  return Wrap(
                    spacing: _gap,
                    runSpacing: _gap,
                    children: [
                      for (final photo in preview)
                        _WorkThumb(url: photo.url, size: cell),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkThumb extends StatelessWidget {
  const _WorkThumb({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: _WorkPhotoImage(rawUrl: url, expand: true),
      ),
    );
  }
}

class _WorkPhotoImage extends StatelessWidget {
  const _WorkPhotoImage({required this.rawUrl, this.expand = false});

  final String rawUrl;
  final bool expand;

  Widget _fallback() => Container(
        color: const Color(0xFFEEEAF6),
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: _D.faint, size: 28),
      );

  @override
  Widget build(BuildContext context) {
    if (isAgendaMediaUrl(rawUrl)) {
      return AgendaMediaImage(
        url: rawUrl,
        fit: BoxFit.cover,
        expand: expand,
        errorWidget: _fallback(),
      );
    }

    final external = rawUrl.trim();
    if (external.startsWith('http://') || external.startsWith('https://')) {
      return SizedBox.expand(
        child: Image.network(
          external,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }

    return _fallback();
  }
}

class _WorksGallerySheet extends StatelessWidget {
  const _WorksGallerySheet({required this.photos});

  final List<BusinessPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final items = _visibleWorkPhotos(photos);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.72;
    final cols = MediaQuery.sizeOf(context).width >= 520 ? 3 : 2;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _D.faint.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(_D.pad, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Algunos trabajos',
                    style: _D.t(17, w: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  color: _D.muted,
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(_D.pad, 0, _D.pad, bottom + 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _WorkPhotoImage(rawUrl: items[i].url, expand: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Equipo ──────────────────────────────────────────────────────────────────

class _Team extends StatelessWidget {
  const _Team({required this.staffAsync});

  final AsyncValue<List<StaffMember>> staffAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHead(title: 'Equipo'),
        const SizedBox(height: 14),
        staffAsync.when(
          loading: () => SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: _D.brand(context)),
            ),
          ),
          error: (_, _) => Text(
            'No se pudo cargar el equipo.',
            style: _D.t(14, c: _D.muted),
          ),
          data: (all) {
            final list = all.where((s) => s.activo).toList();
            if (list.isEmpty) {
              return Text(
                'Este negocio aún no publicó profesionales.',
                style: _D.t(14, c: _D.muted),
              );
            }
            return SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.hardEdge,
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _StaffCard(m: list[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.m});

  static const _cardW = 210.0;
  static const _cardH = 96.0;

  final StaffMember m;

  bool get _rated => m.reviewCount > 0 && m.rating != null;

  String get _initials {
    final w = m.nombre.trim().split(RegExp(r'\s+'));
    if (w.length >= 2) return '${w[0][0]}${w[1][0]}'.toUpperCase();
    return m.nombre.substring(0, m.nombre.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardW,
      height: _cardH,
      child: DecoratedBox(
        decoration: _surfaceDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _BrandSquare(
                size: 48,
                child: _StaffAvatarContent(
                  name: m.nombre,
                  url: m.avatarUrl,
                  initials: _initials,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      m.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _D.t(14, w: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (m.rol != null && m.rol!.trim().isNotEmpty)
                          ? m.rol!.trim()
                          : 'Profesional',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _D.t(12, c: _D.muted),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _rated
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: _D.brand(context),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _rated ? m.rating!.toStringAsFixed(1) : '—',
                          style: _D.t(12, w: FontWeight.w600, c: _D.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffAvatarContent extends StatelessWidget {
  const _StaffAvatarContent({
    required this.name,
    required this.url,
    required this.initials,
  });

  final String name;
  final String? url;
  final String initials;

  @override
  Widget build(BuildContext context) {
    if (url != null && isAgendaMediaUrl(url)) {
      return AgendaMediaImage(
        url: url,
        fit: BoxFit.cover,
        expand: true,
        errorWidget: _initialsLabel(),
      );
    }

    return _initialsLabel();
  }

  Widget _initialsLabel() {
    return Center(
      child: Text(
        initials,
        style: _D.t(16, w: FontWeight.w700, c: _D.white),
      ),
    );
  }
}

// ─── CTA ─────────────────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_D.pageBg(context).withValues(alpha: 0), _D.pageBg(context)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_D.pad, 6, _D.pad, 10),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: _D.brand(context),
                disabledBackgroundColor: _D.brand(context).withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.calendar_month_outlined, color: _D.white, size: 20),
              label: Text(
                'Reservar turno',
                style: _D.t(15, w: FontWeight.w700, c: _D.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
