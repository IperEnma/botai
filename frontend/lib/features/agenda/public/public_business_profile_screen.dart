import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/agenda_address.dart';
import '../../../core/agenda_media_image.dart';
import '../../../core/agenda_media_url.dart';
import '../../../core/openstreetmap_urls.dart';
import '../../../core/open_external_url.dart';
import '../../../core/public_business_share.dart';
import '../../../providers/agenda/public/public_client_session_provider.dart';
import '../../../providers/agenda/public/public_favorites_provider.dart';
import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/business_hours.dart';
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
      theme.background != oldWidget.theme.background;
}

// ─── Design tokens (layout fijo; acento = tema del negocio) ───────────────────

abstract final class _D {
  static Color brand(BuildContext context) =>
      _PublicProfileScope.of(context).primary;

  static Color pageBg(BuildContext context) =>
      _PublicProfileScope.of(context).background;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(publicStaffBySlugProvider(slug));
    final hours = ref.watch(publicHoursBySlugProvider(slug));
    final services = servicesAsync.valueOrNull ?? const [];
    final canBook = services.isNotEmpty;
    final addr = resolveBusinessAddress(business) ?? '';
    final theme = PublicReservarTheme.fromHex(
      colorPrimario: business.colorPrimario,
      colorFondo: business.colorFondo,
      fontFamily: business.fontFamily,
      logoUrl: business.logoUrl,
    );

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
                padding: EdgeInsets.fromLTRB(_D.pad, 14, _D.pad, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _Services(
                      servicesAsync: servicesAsync,
                      onAll: () => _openBookingModal(context),
                      onPick: (svc) => _openBookingModal(context, service: svc),
                    ),
                    const SizedBox(height: 26),
                    _Hours(hoursAsync: hours),
                    const SizedBox(height: 26),
                    _Location(address: addr),
                    const SizedBox(height: 26),
                    _Team(staffAsync: staff),
                  ]),
                ),
              ),
            ],
          ),
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
            left: _D.pad,
            right: _D.pad,
            bottom: _D.bannerIdentityBottom,
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

          // ── Botones superiores ──
          Positioned(
            top: top + 8,
            left: _D.pad,
            child: _RoundBtn(
              icon: Icons.arrow_back_ios_new,
              size: 16,
              onTap: onBack,
            ),
          ),
          Positioned(
            top: top + 8,
            right: _D.pad,
            child: Row(
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
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: BorderRadius.circular(_D.r),
        boxShadow: const [
          BoxShadow(color: _D.shadow, blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

// ─── Servicios ───────────────────────────────────────────────────────────────

class _Services extends StatelessWidget {
  const _Services({
    required this.servicesAsync,
    required this.onAll,
    required this.onPick,
  });

  final AsyncValue<List<AgendaService>> servicesAsync;
  final VoidCallback onAll;
  final ValueChanged<AgendaService> onPick;

  static const _icons = [
    Icons.content_cut_rounded,
    Icons.content_cut_outlined,
    Icons.face_retouching_natural_outlined,
    Icons.brush_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(title: 'Servicios', link: 'Ver todos', onLink: onAll),
        const SizedBox(height: 14),
        servicesAsync.when(
          loading: () => SizedBox(
            height: 132,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _D.brand(context))),
          ),
          error: (_, _) => Text('Error al cargar servicios.', style: _D.t(14, c: _D.muted)),
          data: (list) {
            if (list.isEmpty) {
              return Text('Sin servicios.', style: _D.t(14, c: _D.muted));
            }
            return SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _ServiceCard(
                  svc: list[i],
                  icon: _icons[i % _icons.length],
                  onTap: () => onPick(list[i]),
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
  const _ServiceCard({required this.svc, required this.icon, required this.onTap});

  final AgendaService svc;
  final IconData icon;
  final VoidCallback onTap;

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
      width: 158,
      child: Material(
        color: _D.white,
        borderRadius: BorderRadius.circular(_D.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_D.r),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_D.r),
              boxShadow: const [
                BoxShadow(color: _D.shadow, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _D.brand(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _D.white, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  svc.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _D.t(14, w: FontWeight.w700, h: 1.2),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: _D.faint),
                    const SizedBox(width: 4),
                    Text('${svc.duracionMin} min', style: _D.t(12, c: _D.muted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_price, style: _D.t(15, w: FontWeight.w700, c: _D.brand(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Horarios ────────────────────────────────────────────────────────────────

class _Hours extends StatelessWidget {
  const _Hours({required this.hoursAsync});

  final AsyncValue<List<BusinessHours>> hoursAsync;

  static const _days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHead(title: 'Horarios de atención'),
        const SizedBox(height: 14),
        hoursAsync.when(
          loading: () => SizedBox(
            height: 68,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _D.brand(context))),
          ),
          error: (_, _) => Text('Error al cargar horarios.', style: _D.t(14, c: _D.muted)),
          data: (rows) {
            if (rows.isEmpty) {
              return Text('Sin horarios.', style: _D.t(14, c: _D.muted));
            }
            return _Card(
              pad: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(child: _DayCol(day: _days[d], text: _text(rows, d))),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  static BusinessHours? _find(List<BusinessHours> all, int dow) {
    for (final h in all) {
      if (h.diaSemana == dow) return h;
    }
    return null;
  }

  static String _text(List<BusinessHours> all, int dow) {
    final r = _find(all, dow);
    if (r == null || r.cerrado) return 'Cerrado';
    bool ok(String? a, String? b) => a != null && a.isNotEmpty && b != null && b.isNotEmpty;
    if (ok(r.apertura, r.cierre)) return '${r.apertura} - ${r.cierre}';
    if (ok(r.apertura2, r.cierre2)) return '${r.apertura2} - ${r.cierre2}';
    return 'Cerrado';
  }
}

class _DayCol extends StatelessWidget {
  const _DayCol({required this.day, required this.text});

  final String day;
  final String text;

  bool get _closed => text == 'Cerrado';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(day, style: _D.t(11, w: FontWeight.w600, c: _D.muted)),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: _D.t(
            9.5,
            w: FontWeight.w500,
            c: _closed ? _D.faint : _D.ink,
            h: 1.3,
          ),
        ),
      ],
    );
  }
}

// ─── Ubicación ───────────────────────────────────────────────────────────────

class _Location extends StatelessWidget {
  const _Location({required this.address});

  final String address;

  bool get _hasAddress => address.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final addr = address.trim();
    final mapsUrl = _hasAddress ? OpenStreetMapUrls.search(addr) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHead(title: 'Ubicación'),
        const SizedBox(height: 14),
        _Card(
          pad: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MapThumbnail(address: addr, mapsUrl: mapsUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasAddress) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.place_outlined, size: 18, color: _D.brand(context)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              addr,
                              style: _D.t(13, w: FontWeight.w500, h: 1.35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (mapsUrl != null)
                        GestureDetector(
                          onTap: () => openExternalUrl(mapsUrl),
                          child: Text(
                            'Ver en el mapa >',
                            style: _D.t(13, w: FontWeight.w600, c: _D.brand(context)),
                          ),
                        ),
                    ] else
                      Text(
                        'Agregá la dirección en Estilos o completá el onboarding.',
                        style: _D.t(13, w: FontWeight.w500, h: 1.35, c: _D.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_hasAddress)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text('© OpenStreetMap', style: _D.t(10, c: _D.faint)),
          ),
      ],
    );
  }
}

class _MapThumbnail extends StatefulWidget {
  const _MapThumbnail({required this.address, required this.mapsUrl});

  final String address;
  final String? mapsUrl;

  @override
  State<_MapThumbnail> createState() => _MapThumbnailState();
}

class _MapThumbnailState extends State<_MapThumbnail> {
  String? _thumbUrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  @override
  void didUpdateWidget(_MapThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      _loadThumb();
    }
  }

  Future<void> _loadThumb() async {
    final addr = widget.address.trim();
    if (addr.isEmpty) {
      if (mounted) {
        setState(() {
          _thumbUrl = null;
          _loaded = true;
        });
      }
      return;
    }
    final coords = await OpenStreetMapUrls.geocode(addr);
    if (!mounted) return;
    setState(() {
      _thumbUrl = coords == null
          ? null
          : OpenStreetMapUrls.staticMapThumbnail(
              lat: coords.lat,
              lon: coords.lon,
            );
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const size = 96.0;

    Widget image;
    if (!_loaded) {
      image = Container(
        color: const Color(0xFFE5E7EB),
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _D.brand(context)),
        ),
      );
    } else if (_thumbUrl != null) {
      image = Image.network(
        _thumbUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(size),
      );
    } else {
      image = _placeholder(size);
    }

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: size, height: size, child: image),
    );

    final mapsUrl = widget.mapsUrl;
    if (mapsUrl == null) return clipped;

    return GestureDetector(
      onTap: () => openExternalUrl(mapsUrl),
      child: clipped,
    );
  }

  Widget _placeholder(double size) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _MapGridPainter()),
          Center(
            child: Icon(Icons.location_on, color: _D.brand(context), size: 32),
          ),
        ],
      ),
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
            height: 72,
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
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 28),
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

  final StaffMember m;

  bool get _rated => m.reviewCount > 0 && m.rating != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StaffAvatar(name: m.nombre, url: m.avatarUrl),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                m.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _D.t(15, w: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                (m.rol != null && m.rol!.trim().isNotEmpty)
                    ? m.rol!.trim()
                    : 'Profesional',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _D.t(13, c: _D.muted),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _rated ? Icons.star_rounded : Icons.star_outline_rounded,
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
    );
  }
}

class _StaffAvatar extends StatelessWidget {
  const _StaffAvatar({required this.name, required this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    const sz = 56.0;
    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _D.white, width: 2),
        boxShadow: const [
          BoxShadow(color: _D.shadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? AgendaMediaImage(
              url: url,
              fit: BoxFit.cover,
              width: sz,
              height: sz,
              errorWidget: _initials(sz),
            )
          : _initials(sz),
    );
  }

  Widget _initials(double sz) {
    final w = name.trim().split(RegExp(r'\s+'));
    final l = w.length >= 2
        ? '${w[0][0]}${w[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(1, 2)).toUpperCase();
    return ColoredBox(
      color: const Color(0xFFD1D5DB),
      child: Center(
        child: Text(l, style: _D.t(17, w: FontWeight.w600, c: _D.muted)),
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
