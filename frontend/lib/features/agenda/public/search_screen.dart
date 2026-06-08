import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config.dart';
import '../../../models/agenda/business_summary.dart';
import '../../../core/agenda_icon_registry.dart';
import '../../../models/agenda/category.dart';
import '../../../providers/agenda/public/public_categories_provider.dart';
import '../../../providers/agenda/public/search_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _kPrimary     = Color(0xFF6366F1);
const _kPrimaryDark = Color(0xFF4F46E5);
const _kAccent      = Color(0xFF8B5CF6);
const _kText        = Color(0xFF0F172A);
const _kTextSub     = Color(0xFF64748B);
const _kSurface     = Color(0xFFF1F5F9);
const _kBreakpoint  = 800.0;

// Card layout constants
const _kBandH     = 150.0;                // colored header band height (115 × 1.3)
const _kLogoSz    = 142.0;                // circular logo diameter (129 × 1.1)
const _kCardR     = 20.0;                 // card border radius
const _kLogoSpace = _kLogoSz / 2 + 12.0; // SizedBox below band to clear logo (43 + 12 = 55)

TextStyle _h(double s, {FontWeight w = FontWeight.w700, Color c = _kText}) =>
    GoogleFonts.poppins(fontSize: s, fontWeight: w, color: c);
TextStyle _b(double s, {FontWeight w = FontWeight.w400, Color c = _kTextSub}) =>
    GoogleFonts.poppins(fontSize: s, fontWeight: w, color: c);

// ── Screen ────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _queryCtrl;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController();
    final tenant = AppConfig.agendaDefaultTenantId;
    if (tenant != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchProvider.notifier).setTenantId(tenant);
      });
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  void _clearQuery() {
    _queryCtrl.clear();
    ref.read(searchProvider.notifier).onQueryChanged('');
  }

  void _toggleCategory(Category c) {
    final current = ref.read(searchProvider).categorySlug;
    ref.read(searchProvider.notifier).setCategorySlug(
      current == c.slug ? null : c.slug,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final categoriesAsync = ref.watch(publicCategoriesProvider);

    final activeCatName = state.categorySlug == null
        ? null
        : categoriesAsync
            .whenData((cats) =>
                cats.where((c) => c.slug == state.categorySlug).firstOrNull?.nombre)
            .value;

    return Scaffold(
      backgroundColor: _kSurface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Gradient top section (hero height only, full width) ────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimary, _kPrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SearchNavbar(),
                _SearchHero(
                  queryCtrl: _queryCtrl,
                  hasQuery: state.query.isNotEmpty,
                  onQueryChanged: ref.read(searchProvider.notifier).onQueryChanged,
                  onClear: _clearQuery,
                ),
                // Category chips
                categoriesAsync.when(
                  loading: () => const SizedBox(
                    height: 52,
                    child: Center(
                      child: SizedBox(
                        width: 160,
                        child: LinearProgressIndicator(
                          color: Colors.white54,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (cats) {
                    final activas = cats.where((c) => c.activo).toList();
                    if (activas.isEmpty) return const SizedBox.shrink();
                    return _CategoryStrip(
                      categories: activas,
                      selectedSlug: state.categorySlug,
                      onSelect: _toggleCategory,
                    );
                  },
                ),
                // Active filter pill — centered, same flow as tags
                if (activeCatName != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.filter_alt_rounded,
                                size: 13, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(activeCatName,
                                style: _b(12,
                                    w: FontWeight.w600, c: Colors.white)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => ref
                                  .read(searchProvider.notifier)
                                  .setCategorySlug(null),
                              child: const Icon(Icons.close_rounded,
                                  size: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Results bar ───────────────────────────────────────────────
          _ResultsBar(state: state),
          // ── Cards area (light background) ─────────────────────────────
          Expanded(child: _BusinessGrid(state: state)),
        ],
      ),
    );
  }

}

// ── White navbar ──────────────────────────────────────────────────────────────

class _SearchNavbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _kBreakpoint;

    return Container(
      height: MediaQuery.of(context).padding.top + 56,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/'),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kPrimary, _kAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.calendar_month,
                        color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 8),
                  Text('AgendaKonecta', style: _h(15, w: FontWeight.w800)),
                ],
              ),
            ),
            const Spacer(),
            if (wide) ...[
              TextButton(
                onPressed: () => context.go('/'),
                child: Text('Inicio',
                    style: _b(13, w: FontWeight.w500, c: _kTextSub)),
              ),
              const SizedBox(width: 4),
            ],
            FilledButton(
              onPressed: () => context.go('/agenda/register'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(0, 36),
              ),
              child: Text(
                wide ? 'Registrá tu negocio' : 'Registrarse',
                style: _b(13, w: FontWeight.w600, c: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero section ─────────────────────────────────────────────────────────────

class _SearchHero extends StatelessWidget {
  const _SearchHero({
    required this.queryCtrl,
    required this.hasQuery,
    required this.onQueryChanged,
    required this.onClear,
  });

  final TextEditingController queryCtrl;
  final bool hasQuery;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _kBreakpoint;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Profesionales y Empresas',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Encontrá el servicio que buscás cerca tuyo',
            textAlign: TextAlign.center,
            style: _b(14, c: Colors.white.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width *
                  (wide ? 0.38 : 0.92),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: queryCtrl,
                onChanged: onQueryChanged,
                style: _h(15, w: FontWeight.w400, c: _kText),
                decoration: InputDecoration(
                  hintText: 'Nombre, rubro, profesión…',
                  hintStyle: _b(15),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: _kTextSub),
                  suffixIcon: hasQuery
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: _kTextSub, size: 18),
                          onPressed: onClear,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category strip ────────────────────────────────────────────────────────────

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedSlug,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedSlug;
  final ValueChanged<Category> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: categories.map((c) {
            final selected = selectedSlug == c.slug;
            return GestureDetector(
              onTap: () => onSelect(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AgendaIconRegistry.forCategory(
                        slug: c.slug,
                        icono: c.icono,
                      ),
                      size: 14,
                      color: selected ? _kPrimary : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      c.nombre,
                      textAlign: TextAlign.center,
                      style: _b(12,
                          w: FontWeight.w600,
                          c: selected ? _kPrimary : Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Results bar ───────────────────────────────────────────────────────────────

class _ResultsBar extends StatelessWidget {
  const _ResultsBar({required this.state});

  final SearchState state;

  String _label() {
    if (state.categorySlug != null && state.query.isNotEmpty) {
      return 'Resultados en "${state.query}"';
    }
    if (state.categorySlug != null) return 'Negocios en esta categoría';
    if (state.query.isNotEmpty) return 'Resultados para "${state.query}"';
    return 'Todos los negocios';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= _kBreakpoint;
    final hPad = wide ? size.width * 0.18 : 12.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _label(),
              style: _h(15, w: FontWeight.w600, c: _kText),
            ),
          ),
          if (state.isLoading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kTextSub),
            )
          else if (state.hasSearched)
            Text(
              '${state.results.length} resultado${state.results.length == 1 ? '' : 's'}',
              style: _b(14, c: _kText),
            ),
        ],
      ),
    );
  }
}

// ── Business grid ─────────────────────────────────────────────────────────────

class _BusinessGrid extends ConsumerWidget {
  const _BusinessGrid({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: ref.read(searchProvider.notifier).retry,
      );
    }

    if (state.hasSearched && state.results.isEmpty && !state.isLoading) {
      return AgendaEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        subtitle: state.categorySlug != null
            ? 'No hay negocios en esta categoría todavía.'
            : 'Probá con otro nombre o rubro.',
      );
    }

    if (state.isLoading && state.results.isEmpty) {
      return const AgendaLoadingView(message: 'Cargando negocios…');
    }

    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= _kBreakpoint;
    // Desktop: 20% lateral margins → cards occupy ~60% of screen width
    // Mobile: small fixed padding
    final hPad = wide ? size.width * 0.18 : 12.0;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 40),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 3 : 2,
        mainAxisExtent: wide ? 468 : 444,
        crossAxisSpacing: 32, // 21 × 1.5
        mainAxisSpacing: 32,
      ),
      itemCount: state.results.length,
      itemBuilder: (context, i) {
        final b = state.results[i];
        return _BusinessCard(
          business: b,
          onTap: () {
            final path = b.profilePath;
            if (path != null) {
              context.go(path);
            }
          },
        );
      },
    );
  }
}

// ── Business card ─────────────────────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.business, required this.onTap});

  final BusinessSummary business;
  final VoidCallback onTap;

  // Color palette — two variants per entry (band gradient)
  static const _palette = [
    Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899),
    Color(0xFF14B8A6), Color(0xFF22C55E), Color(0xFFF59E0B),
    Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFF84CC16),
  ];
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(_kCardR),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kCardR),
        child: Material(
          color: const Color(0xFFF3F4F6),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // ── Card base ─────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header band — uniform primary color + subtle wave overlay
                    Container(
                      height: _kBandH,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(_kCardR),
                          topRight: Radius.circular(_kCardR),
                        ),
                      ),
                      child: CustomPaint(
                        painter: const _WavePainter(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    // Logo + title row: logo is overlaid via Positioned,
                    // this Row reserves space and places the title to its right
                    SizedBox(
                      height: _kLogoSpace,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reserve horizontal space for logo (left margin + size + gap)
                          SizedBox(width: _kLogoSz + 28),
                          // Title aligned with top of logo's body portion
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(0, 8, 14, 0),
                              child: Text(
                                business.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _h(17, w: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chips, description, location
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chips — left aligned
                            if (business.categorias.isNotEmpty)
                              Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 6,
                                runSpacing: 6,
                                children: business.categorias
                                    .take(3)
                                    .map((cat) => _ChipLabel(
                                          label: cat,
                                          color: _color,
                                        ))
                                    .toList(),
                              ),
                            // Description — left aligned, symmetric horizontal padding
                            if (business.descripcion != null &&
                                business.descripcion!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Text(
                                  business.descripcion!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: _b(11),
                                ),
                              ),
                            ],
                            const Spacer(),
                            // Location — left aligned
                            if (business.direccionCorta != null)
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 11,
                                      color: _color.withValues(alpha: 0.7)),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      business.direccionCorta!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _b(10),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Logo — left-aligned, overlapping band/body ────────
                Positioned(
                  top: _kBandH - _kLogoSz / 2,
                  left: 16,
                  width: _kLogoSz,
                  height: _kLogoSz,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
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
                              errorBuilder: (_, _, _) => _InitialsCircle(
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
                ),

                // ── Badge — top-right inside band ──────────────────────
                Positioned(
                  top: 15,
                  right: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      business.activo ? 'Activo' : 'Inactivo',
                      style: _b(9, w: FontWeight.w700, c: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Wave painter ─────────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    _wave(canvas, size, paint, yRatio: 0.26, amp: 7, phase: 0.0);
    _wave(canvas, size, paint, yRatio: 0.56, amp: 10, phase: math.pi * 0.8);
    _wave(canvas, size, paint, yRatio: 0.83, amp: 6, phase: math.pi * 1.5);
  }

  void _wave(
    Canvas canvas,
    Size size,
    Paint paint, {
    required double yRatio,
    required double amp,
    required double phase,
  }) {
    final path = Path();
    final yBase = size.height * yRatio;
    final freq = 2 * math.pi / (size.width * 0.6);
    path.moveTo(0, yBase + amp * math.sin(phase));
    for (double x = 1; x <= size.width; x++) {
      path.lineTo(x, yBase + amp * math.sin(freq * x + phase));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => false;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _b(9, w: FontWeight.w600, c: color),
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({required this.initials, required this.color});

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.12),
      child: Center(
        child: Text(initials, style: _h(20, c: color)),
      ),
    );
  }
}
