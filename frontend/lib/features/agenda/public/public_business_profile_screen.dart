import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config.dart';
import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/business_hours.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

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

// ─── Design tokens (mockup Felito Barber — fijos) ─────────────────────────────

abstract final class _D {
  static const purple = Color(0xFF7C5CFF);
  static const bg = Color(0xFFF3F4F6);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const faint = Color(0xFF9CA3AF);
  static const white = Colors.white;
  static const shadow = Color(0x12000000);

  static const pad = 16.0;
  static const r = 16.0;
  static const bannerH = 252.0;
  static const logo = 88.0;
  static const logoBorder = 3.5;
  static const logoLift = 44.0;

  static TextStyle t(
    double s, {
    FontWeight w = FontWeight.w400,
    Color c = ink,
    double? h,
  }) =>
      GoogleFonts.inter(fontSize: s, fontWeight: w, color: c, height: h);
}

String? _mediaUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final u = raw.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  if (u.startsWith('/')) return '${AppConfig.serverBaseUrl}$u';
  return '${AppConfig.serverBaseUrl}/$u';
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

  void _book(BuildContext c) {
    final co = GoRouterState.of(c).uri.queryParameters['company'];
    var p = '/reservar/$slug/reservar';
    if (co != null && co.isNotEmpty) p = '$p?company=$co';
    c.go(p);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(publicStaffBySlugProvider(slug));
    final hours = ref.watch(publicHoursBySlugProvider(slug));
    final services = servicesAsync.valueOrNull ?? const [];
    final canBook = services.isNotEmpty;
    final addr = business.direccion?.trim() ?? '';

    return Scaffold(
      backgroundColor: _D.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  business: business,
                  onBack: () => _back(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(_D.pad, 4, _D.pad, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _Services(
                      servicesAsync: servicesAsync,
                      onAll: () => _book(context),
                      onPick: (_) => _book(context),
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
              onTap: canBook ? () => _book(context) : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.business, required this.onBack});

  final Business business;
  final VoidCallback onBack;

  List<String> get _categoryLabels {
    if (business.categorias.isNotEmpty) {
      return business.categorias.take(3).toList();
    }
    if (business.searchTags.isNotEmpty) {
      return business.searchTags.take(3).toList();
    }
    return const [];
  }

  String get _ratingLabel {
    if (business.reviewCount > 0 && business.rating != null) {
      return '${business.rating!.toStringAsFixed(1)} (${business.reviewCount} reseñas)';
    }
    return 'Sin reseñas aún';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bannerUrl = _mediaUrl(business.bannerUrl);
    final logoUrl = _mediaUrl(business.logoUrl);
    final cats = _categoryLabels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: _D.bannerH + top,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bannerUrl != null)
                    Image.network(
                      bannerUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _BannerFallback(),
                    )
                  else
                    const _BannerFallback(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: _D.bannerH * 0.72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.88),
                          ],
                          stops: const [0, 0.4, 1],
                        ),
                      ),
                    ),
                  ),
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
                        _RoundBtn(icon: Icons.ios_share, onTap: () {}),
                        const SizedBox(width: 8),
                        const _HeartBtn(),
                      ],
                    ),
                  ),
                  Positioned(
                    left: _D.pad + _D.logo + 12,
                    right: _D.pad,
                    bottom: _D.logoLift + 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _D.t(20, w: FontWeight.w700, c: _D.white, h: 1.15),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _Stars(rating: business.rating ?? 0),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _ratingLabel,
                                style: _D.t(13, w: FontWeight.w500, c: _D.white),
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
                              for (final c in cats) _Pill(_prettyCat(c)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: _D.pad,
              top: top + _D.bannerH - _D.logoLift,
              child: _LogoCircle(name: business.nombre, url: logoUrl),
            ),
          ],
        ),
        SizedBox(height: _D.logoLift + 6),
      ],
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

class _HeartBtn extends StatefulWidget {
  const _HeartBtn();

  @override
  State<_HeartBtn> createState() => _HeartBtnState();
}

class _HeartBtnState extends State<_HeartBtn> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _RoundBtn(
      icon: _on ? Icons.favorite : Icons.favorite_border,
      onTap: () => setState(() => _on = !_on),
    );
  }
}

class _LogoCircle extends StatelessWidget {
  const _LogoCircle({required this.name, required this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final ok = url != null;
    return Container(
      width: _D.logo,
      height: _D.logo,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _D.white, width: _D.logoBorder),
        boxShadow: const [
          BoxShadow(color: _D.shadow, blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ok
          ? Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fb())
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
  const _Stars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final n = i + 1;
        return Icon(
          rating >= n - 0.25 ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: _D.purple,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: _D.purple,
        borderRadius: BorderRadius.circular(20),
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
            child: Text('$link >', style: _D.t(13, w: FontWeight.w600, c: _D.purple)),
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
          loading: () => const SizedBox(
            height: 132,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _D.purple)),
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
                    color: _D.purple,
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
                Text(_price, style: _D.t(15, w: FontWeight.w700, c: _D.purple)),
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
          loading: () => const SizedBox(
            height: 68,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _D.purple)),
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
    final text = _hasAddress ? address.trim() : 'Agregá la dirección desde el panel del negocio';

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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 96,
                  height: 96,
                  color: const Color(0xFFE5E7EB),
                  child: const Icon(Icons.location_on, color: _D.purple, size: 32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_outlined, size: 18, color: _D.purple),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            text,
                            style: _D.t(
                              13,
                              w: FontWeight.w500,
                              h: 1.35,
                              c: _hasAddress ? _D.ink : _D.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_hasAddress) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ver en el mapa >',
                        style: _D.t(13, w: FontWeight.w600, c: _D.purple),
                      ),
                    ],
                  ],
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

class _Team extends StatelessWidget {
  const _Team({required this.staffAsync});

  final AsyncValue<List<StaffMember>> staffAsync;

  @override
  Widget build(BuildContext context) {
    return staffAsync.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (all) {
        final list = all.where((s) => s.activo).toList();
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHead(title: 'Equipo'),
            const SizedBox(height: 14),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 24),
                itemBuilder: (_, i) => _StaffRow(m: list[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.m});

  final StaffMember m;

  bool get _rated => m.reviewCount > 0 && m.rating != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Avatar(name: m.nombre, url: m.avatarUrl),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(m.nombre, style: _D.t(15, w: FontWeight.w700)),
            Text(
              (m.rol != null && m.rol!.trim().isNotEmpty) ? m.rol!.trim() : 'Profesional',
              style: _D.t(13, c: _D.muted),
            ),
            if (_rated)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 13, color: _D.purple),
                  const SizedBox(width: 2),
                  Text(m.rating!.toStringAsFixed(1), style: _D.t(12, w: FontWeight.w600)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    const sz = 52.0;
    final resolved = _mediaUrl(url);
    final ok = resolved != null;
    return ClipOval(
      child: SizedBox(
        width: sz,
        height: sz,
        child: ok
            ? Image.network(resolved, fit: BoxFit.cover, errorBuilder: (_, _, _) => _ini(sz))
            : _ini(sz),
      ),
    );
  }

  Widget _ini(double sz) {
    final w = name.trim().split(RegExp(r'\s+'));
    final l = w.length >= 2
        ? '${w[0][0]}${w[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(1, 2)).toUpperCase();
    return ColoredBox(
      color: const Color(0xFFD1D5DB),
      child: Center(child: Text(l, style: _D.t(16, w: FontWeight.w600, c: _D.muted))),
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
          colors: [_D.bg.withValues(alpha: 0), _D.bg],
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
                backgroundColor: _D.purple,
                disabledBackgroundColor: _D.purple.withValues(alpha: 0.4),
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
