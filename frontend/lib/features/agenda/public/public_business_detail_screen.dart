import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/business_hours.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../tenant/tabs/styles/brand_style.dart';

/// Perfil público — `/reservar/:slug` (mockup Felito Barber).
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
      data: (b) => _FelitoProfilePage(
        business: b,
        servicesAsync: servicesAsync,
        slug: slug,
      ),
    );
  }
}

/// Tokens fijos del mockup Felito Barber (+ color primario del negocio).
abstract final class _FelitoSpec {
  static const primaryFallback = Color(0xFF7C5CFF);
  static const pageBg = Color(0xFFF5F6F8);
  static const ink = Color(0xFF111827);
  static const inkSub = Color(0xFF6B7280);
  static const inkMuted = Color(0xFF9CA3AF);
  static const mapBg = Color(0xFFE8E4DC);
  static const mapPin = Color(0xFF4285F4);
  static const cardShadow = Color(0x14000000);

  static const hPad = 20.0;
  static const sectionGap = 28.0;
  static const cardRadius = 16.0;
  static const chipRadius = 20.0;
  static const ctaRadius = 14.0;

  static const bannerHeight = 236.0;
  static const logoSize = 92.0;
  static const logoBorder = 4.0;
  static const logoOverhang = 46.0;

  static const serviceCardW = 162.0;
  static const serviceCardH = 138.0;
  static const serviceIcon = 44.0;

  static TextStyle inter(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
}

class _FelitoProfilePage extends ConsumerWidget {
  const _FelitoProfilePage({
    required this.business,
    required this.servicesAsync,
    required this.slug,
  });

  final Business business;
  final AsyncValue<List<AgendaService>> servicesAsync;
  final String slug;

  Color get _primary {
    final hex = business.colorPrimario;
    if (hex != null && hex.isNotEmpty) {
      return parseHex(hex, fallback: _FelitoSpec.primaryFallback);
    }
    return _FelitoSpec.primaryFallback;
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _openBooking(BuildContext context) {
    final company = GoRouterState.of(context).uri.queryParameters['company'];
    var path = '/reservar/$slug/reservar';
    if (company != null && company.isNotEmpty) {
      path = '$path?company=$company';
    }
    context.go(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = _primary;
    final staffAsync = ref.watch(publicStaffBySlugProvider(slug));
    final hoursAsync = ref.watch(publicHoursBySlugProvider(slug));
    final services = servicesAsync.valueOrNull ?? const <AgendaService>[];
    final canBook = services.isNotEmpty;
    final direccion = business.direccion?.trim();

    return Scaffold(
      backgroundColor: _FelitoSpec.pageBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroBlock(
                  primary: primary,
                  business: business,
                  onBack: () => _goBack(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  _FelitoSpec.hPad,
                  8,
                  _FelitoSpec.hPad,
                  96,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ServicesBlock(
                      primary: primary,
                      servicesAsync: servicesAsync,
                      onSeeAll: () => _openBooking(context),
                      onServiceTap: (_) => _openBooking(context),
                    ),
                    const SizedBox(height: _FelitoSpec.sectionGap),
                    _HoursBlock(primary: primary, hoursAsync: hoursAsync),
                    const SizedBox(height: _FelitoSpec.sectionGap),
                    _LocationBlock(
                      primary: primary,
                      direccion: direccion?.isNotEmpty == true
                          ? direccion!
                          : 'Dirección no disponible',
                      hasAddress: direccion?.isNotEmpty == true,
                    ),
                    const SizedBox(height: _FelitoSpec.sectionGap),
                    _TeamBlock(primary: primary, staffAsync: staffAsync),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StickyCta(
              primary: primary,
              enabled: canBook,
              onPressed: canBook ? () => _openBooking(context) : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero: banner + logo que invade el contenido ─────────────────────────────

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({
    required this.primary,
    required this.business,
    required this.onBack,
  });

  final Color primary;
  final Business business;
  final VoidCallback onBack;

  bool get _hasBanner =>
      business.bannerUrl != null && business.bannerUrl!.startsWith('http');

  bool get _hasRating =>
      business.reviewCount > 0 && business.rating != null;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _FelitoSpec.bannerHeight + top,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_hasBanner)
                    Image.network(
                      business.bannerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _bannerGradient(primary),
                    )
                  else
                    _bannerGradient(primary),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.62),
                        ],
                        stops: const [0.45, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    top: top + 10,
                    left: _FelitoSpec.hPad,
                    child: _CircleBtn(
                      icon: Icons.arrow_back_ios_new,
                      size: 16,
                      onTap: onBack,
                    ),
                  ),
                  Positioned(
                    top: top + 10,
                    right: _FelitoSpec.hPad,
                    child: Row(
                      children: [
                        _CircleBtn(icon: Icons.ios_share, onTap: () {}),
                        const SizedBox(width: 8),
                        const _HeartBtn(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _FelitoSpec.logoOverhang + 8),
          ],
        ),
        Positioned(
          left: _FelitoSpec.hPad,
          top: top + _FelitoSpec.bannerHeight - _FelitoSpec.logoOverhang,
          right: _FelitoSpec.hPad,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogoAvatar(
                nombre: business.nombre,
                url: business.logoUrl,
                size: _FelitoSpec.logoSize,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _FelitoSpec.inter(
                          21,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      if (_hasRating) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _PurpleStars(
                              rating: business.rating!,
                              color: primary,
                              size: 17,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${business.rating!.toStringAsFixed(1)} (${business.reviewCount} reseñas)',
                                style: _FelitoSpec.inter(
                                  13,
                                  weight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (business.categorias.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final c in business.categorias.take(3))
                              _TagChip(primary: primary, label: _label(c)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _label(String slug) {
    if (slug.isEmpty) return slug;
    return slug
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _bannerGradient(Color primary) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            Color.lerp(primary, const Color(0xFF5B21B6), 0.35)!,
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    this.size = 18,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: _FelitoSpec.cardShadow,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: size, color: _FelitoSpec.ink),
        ),
      ),
    );
  }
}

class _HeartBtn extends StatefulWidget {
  const _HeartBtn();

  @override
  State<_HeartBtn> createState() => _HeartBtnState();
}

class _HeartBtnState extends State<_HeartBtn> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _CircleBtn(
      icon: _on ? Icons.favorite : Icons.favorite_border,
      onTap: () => setState(() => _on = !_on),
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({
    required this.nombre,
    required this.url,
    required this.size,
  });

  final String nombre;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.startsWith('http');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: _FelitoSpec.logoBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasUrl
          ? Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fb())
          : _fb(),
    );
  }

  Widget _fb() {
    final w = nombre.trim().split(RegExp(r'\s+'));
    final ini = w.length >= 2
        ? '${w[0][0]}${w[1][0]}'.toUpperCase()
        : nombre.substring(0, nombre.length.clamp(1, 2)).toUpperCase();
    return ColoredBox(
      color: const Color(0xFF141414),
      child: Center(
        child: Text(
          ini,
          style: _FelitoSpec.inter(size * 0.26, weight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.primary, required this.label});

  final Color primary;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(_FelitoSpec.chipRadius),
      ),
      child: Text(
        label,
        style: _FelitoSpec.inter(12, weight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

class _PurpleStars extends StatelessWidget {
  const _PurpleStars({
    required this.rating,
    required this.color,
    this.size = 16,
  });

  final double rating;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final n = i + 1;
        IconData icon;
        if (rating >= n) {
          icon = Icons.star_rounded;
        } else if (rating >= n - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_rounded;
        }
        final filled = rating >= n - 0.25;
        return Icon(
          icon,
          size: size,
          color: filled ? color : color.withValues(alpha: 0.28),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.action,
    this.onAction,
    this.actionColor = _FelitoSpec.primaryFallback,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Color actionColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: _FelitoSpec.inter(17, weight: FontWeight.w700),
          ),
        ),
        if (action != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              '$action >',
              style: _FelitoSpec.inter(
                13,
                weight: FontWeight.w600,
                color: actionColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_FelitoSpec.cardRadius),
        boxShadow: const [
          BoxShadow(
            color: _FelitoSpec.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Servicios ───────────────────────────────────────────────────────────────

class _ServicesBlock extends StatelessWidget {
  const _ServicesBlock({
    required this.primary,
    required this.servicesAsync,
    required this.onSeeAll,
    required this.onServiceTap,
  });

  final Color primary;
  final AsyncValue<List<AgendaService>> servicesAsync;
  final VoidCallback onSeeAll;
  final ValueChanged<AgendaService> onServiceTap;

  static const _icons = [
    Icons.content_cut_rounded,
    Icons.content_cut_outlined,
    Icons.brush_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Servicios',
          action: 'Ver todos',
          onAction: onSeeAll,
          actionColor: primary,
        ),
        const SizedBox(height: 14),
        servicesAsync.when(
          loading: () => const SizedBox(
            height: _FelitoSpec.serviceCardH,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => Text(
            'No se pudieron cargar los servicios.',
            style: _FelitoSpec.inter(14, color: _FelitoSpec.inkSub),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                'Sin servicios publicados.',
                style: _FelitoSpec.inter(14, color: _FelitoSpec.inkSub),
              );
            }
            return SizedBox(
              height: _FelitoSpec.serviceCardH,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _ServiceTile(
                  primary: primary,
                  service: list[i],
                  icon: _icons[i % _icons.length],
                  onTap: () => onServiceTap(list[i]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.primary,
    required this.service,
    required this.icon,
    required this.onTap,
  });

  final Color primary;
  final AgendaService service;
  final IconData icon;
  final VoidCallback onTap;

  String get _price {
    final n = service.precio.round();
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
      width: _FelitoSpec.serviceCardW,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_FelitoSpec.cardRadius),
        elevation: 0,
        shadowColor: _FelitoSpec.cardShadow,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_FelitoSpec.cardRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_FelitoSpec.cardRadius),
              boxShadow: const [
                BoxShadow(
                  color: _FelitoSpec.cardShadow,
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _FelitoSpec.serviceIcon,
                  height: _FelitoSpec.serviceIcon,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primary, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  service.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _FelitoSpec.inter(14, weight: FontWeight.w700, height: 1.2),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 13, color: _FelitoSpec.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${service.duracionMin} min',
                      style: _FelitoSpec.inter(12, color: _FelitoSpec.inkSub),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _price,
                  style: _FelitoSpec.inter(16, weight: FontWeight.w700, color: primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Horarios ────────────────────────────────────────────────────────────────

class _HoursBlock extends StatelessWidget {
  const _HoursBlock({required this.primary, required this.hoursAsync});

  final Color primary;
  final AsyncValue<List<BusinessHours>> hoursAsync;

  static const _days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Horarios de atención'),
        const SizedBox(height: 14),
        hoursAsync.when(
          loading: () => const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => Text(
            'No se pudieron cargar los horarios.',
            style: _FelitoSpec.inter(14, color: _FelitoSpec.inkSub),
          ),
          data: (hours) {
            if (hours.isEmpty) {
              return Text(
                'Horarios no publicados.',
                style: _FelitoSpec.inter(14, color: _FelitoSpec.inkSub),
              );
            }
            return _WhiteCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: _DayCell(
                        day: _days[d],
                        lines: _lines(_find(hours, d)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  BusinessHours? _find(List<BusinessHours> all, int dow) {
    for (final h in all) {
      if (h.diaSemana == dow) return h;
    }
    return null;
  }

  List<String> _lines(BusinessHours? row) {
    if (row == null || row.cerrado) return const ['Cerrado'];
    bool ok(String? a, String? c) =>
        a != null && a.isNotEmpty && c != null && c.isNotEmpty;
    final out = <String>[];
    if (ok(row.apertura, row.cierre)) {
      out.add('${row.apertura} - ${row.cierre}');
    }
    if (ok(row.apertura2, row.cierre2)) {
      out.add('${row.apertura2} - ${row.cierre2}');
    }
    return out.isEmpty ? const ['Cerrado'] : out;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.lines});

  final String day;
  final List<String> lines;

  bool get _closed => lines.length == 1 && lines.first == 'Cerrado';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day,
          style: _FelitoSpec.inter(
            11,
            weight: FontWeight.w600,
            color: _FelitoSpec.inkSub,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          Text(
            lines[i],
            textAlign: TextAlign.center,
            style: _FelitoSpec.inter(
              9.5,
              weight: FontWeight.w500,
              color: _closed ? _FelitoSpec.inkMuted : _FelitoSpec.ink,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Ubicación ───────────────────────────────────────────────────────────────

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({
    required this.primary,
    required this.direccion,
    required this.hasAddress,
  });

  final Color primary;
  final String direccion;
  final bool hasAddress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Ubicación'),
        const SizedBox(height: 14),
        _WhiteCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 100,
                  height: 100,
                  color: _FelitoSpec.mapBg,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: _FelitoSpec.mapPin,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.place_outlined, size: 18, color: primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              direccion,
                              style: _FelitoSpec.inter(
                                13.5,
                                weight: FontWeight.w500,
                                height: 1.35,
                                color: hasAddress
                                    ? _FelitoSpec.ink
                                    : _FelitoSpec.inkSub,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (hasAddress) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Ver en el mapa >',
                          style: _FelitoSpec.inter(
                            13,
                            weight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ],
                    ],
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

// ─── Equipo ──────────────────────────────────────────────────────────────────

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({required this.primary, required this.staffAsync});

  final Color primary;
  final AsyncValue<List<StaffMember>> staffAsync;

  @override
  Widget build(BuildContext context) {
    return staffAsync.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (all) {
        final staff = all.where((s) => s.activo).toList();
        if (staff.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Equipo'),
            const SizedBox(height: 14),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: staff.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _StaffCard(primary: primary, member: staff[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.primary, required this.member});

  final Color primary;
  final StaffMember member;

  bool get _rated => member.reviewCount > 0 && member.rating != null;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StaffPhoto(nombre: member.nombre, url: member.avatarUrl),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                member.nombre,
                style: _FelitoSpec.inter(15, weight: FontWeight.w700),
              ),
              Text(
                (member.rol != null && member.rol!.trim().isNotEmpty)
                    ? member.rol!.trim()
                    : 'Profesional',
                style: _FelitoSpec.inter(13, color: _FelitoSpec.inkSub),
              ),
              if (_rated)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: primary),
                    const SizedBox(width: 3),
                    Text(
                      member.rating!.toStringAsFixed(1),
                      style: _FelitoSpec.inter(12, weight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffPhoto extends StatelessWidget {
  const _StaffPhoto({required this.nombre, required this.url});

  final String nombre;
  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final ok = url != null && url!.startsWith('http');
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ok
          ? Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _ini(size))
          : _ini(size),
    );
  }

  Widget _ini(double size) {
    final w = nombre.trim().split(RegExp(r'\s+'));
    final l = w.length >= 2
        ? '${w[0][0]}${w[1][0]}'.toUpperCase()
        : nombre.substring(0, nombre.length.clamp(1, 2)).toUpperCase();
    return ColoredBox(
      color: const Color(0xFFE5E7EB),
      child: Center(
        child: Text(
          l,
          style: _FelitoSpec.inter(18, weight: FontWeight.w600, color: _FelitoSpec.inkSub),
        ),
      ),
    );
  }
}

// ─── CTA ─────────────────────────────────────────────────────────────────────

class _StickyCta extends StatelessWidget {
  const _StickyCta({
    required this.primary,
    required this.enabled,
    required this.onPressed,
  });

  final Color primary;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _FelitoSpec.pageBg.withValues(alpha: 0),
            _FelitoSpec.pageBg,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _FelitoSpec.hPad,
            8,
            _FelitoSpec.hPad,
            12,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                disabledBackgroundColor: primary.withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_FelitoSpec.ctaRadius),
                ),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 20),
              label: Text(
                'Reservar turno',
                style: _FelitoSpec.inter(15, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
