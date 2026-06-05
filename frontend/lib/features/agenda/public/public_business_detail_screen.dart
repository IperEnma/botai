import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/business.dart';
import '../../../providers/agenda/public/public_business_detail_provider.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen entry point
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
      data: (b) => _DetailPage(business: b, servicesAsync: servicesAsync),
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
      data: (b) => _DetailPage(business: b, servicesAsync: servicesAsync, slug: slug),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full page
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPage extends StatelessWidget {
  const _DetailPage({required this.business, required this.servicesAsync, this.slug});

  final Business business;
  final AsyncValue<List<AgendaService>> servicesAsync;
  final String? slug;

  Color get _primaryColor {
    final hex = business.colorPrimario;
    if (hex == null) return const Color(0xFF6366F1);
    final val = int.tryParse('FF${hex.replaceAll('#', '')}', radix: 16);
    return val != null ? Color(val) : const Color(0xFF6366F1);
  }

  Color get _bgColor {
    final hex = business.colorFondo;
    if (hex == null) return Colors.white;
    final val = int.tryParse('FF${hex.replaceAll('#', '')}', radix: 16);
    return val != null ? Color(val) : Colors.white;
  }

  bool get _bgIsDark => _bgColor.computeLuminance() < 0.4;

  String get _fontFamily => business.fontFamily ?? 'Roboto';

  bool get _hasSocial =>
      business.instagramUrl != null ||
      business.tiktokUrl != null ||
      business.facebookUrl != null;

  void _openBooking(BuildContext context, AgendaService? service,
      List<AgendaService> services, {String? slug}) {
    final targetSlug = (slug != null && slug.isNotEmpty)
        ? slug
        : business.publicSlug;
    if (targetSlug != null && targetSlug.isNotEmpty) {
      context.go('/reservar/$targetSlug');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reservá desde el enlace público del negocio.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = _primaryColor;
    final bg = _bgColor;
    final dark = _bgIsDark;
    final font = _fontFamily;
    final textColor = dark ? Colors.white : Colors.black87;
    final subColor = dark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Pinned app bar ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            title: Text(business.nombre,
                style: const TextStyle(color: Colors.white)),
            expandedHeight: 0,
          ),

          // ── Header: banner + avatar + info ────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: bg,
              child: Column(
                children: [
                  Container(height: 80, color: primary),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Column(
                      children: [
                        _AvatarCircle(
                          logoUrl: business.logoUrl,
                          nombre: business.nombre,
                          color: primary,
                          size: 80,
                          borderColor: bg,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            business.nombre,
                            textAlign: TextAlign.center,
                            style: _fs(font,
                                size: 22,
                                weight: FontWeight.w700,
                                color: textColor),
                          ),
                        ),
                        if (business.descripcion != null &&
                            business.descripcion!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              business.descripcion!,
                              textAlign: TextAlign.center,
                              style: _fs(font, size: 14, color: subColor),
                            ),
                          ),
                        ],
                        if (business.categorias.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final cat
                                  in business.categorias.take(4))
                                Chip(
                                  label: Text(cat,
                                      style: _fs(font,
                                          size: 11, color: primary)),
                                  backgroundColor:
                                      primary.withValues(alpha: 0.1),
                                  side: BorderSide.none,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                  labelPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8),
                                ),
                            ],
                          ),
                        ],
                        if (_hasSocial) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              if (business.instagramUrl != null)
                                _SocialChip(
                                    label: 'Instagram', color: primary),
                              if (business.tiktokUrl != null)
                                _SocialChip(
                                    label: 'TikTok', color: primary),
                              if (business.facebookUrl != null)
                                _SocialChip(
                                    label: 'Facebook', color: primary),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        // CTA button (opens booking flow)
                        servicesAsync.when(
                          loading: () => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                onPressed: null,
                                child: Text('Reservar turno',
                                    style: _fs(font,
                                        size: 15,
                                        weight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (services) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                onPressed: services.isEmpty
                                    ? null
                                    : () => _openBooking(
                                        context, null, services, slug: slug),
                                child: Text(
                                    services.isEmpty
                                        ? 'Sin servicios disponibles'
                                        : 'Reservar turno',
                                    style: _fs(font,
                                        size: 15,
                                        weight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Services section ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: bg,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                      color: dark
                          ? Colors.white24
                          : Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text('Servicios',
                      style: _fs(font,
                          size: 16,
                          weight: FontWeight.w700,
                          color: textColor)),
                  const SizedBox(height: 12),
                  servicesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Text(
                      'No se pudieron cargar los servicios.',
                      style: TextStyle(color: subColor),
                    ),
                    data: (list) => list.isEmpty
                        ? Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Este negocio todavía no publicó servicios.',
                              style: TextStyle(color: subColor),
                            ),
                          )
                        : Column(
                            children: [
                              for (final s in list)
                                _ServiceTile(
                                  service: s,
                                  primaryColor: primary,
                                  fontFamily: font,
                                  dark: dark,
                                  onBook: () => _openBooking(
                                      context, s, list, slug: slug),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.logoUrl,
    required this.nombre,
    required this.color,
    this.size = 80,
    this.borderColor,
  });

  final String? logoUrl;
  final String nombre;
  final Color color;
  final double size;
  final Color? borderColor;

  String get _initials {
    final words = nombre.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 3)
            : Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl!.startsWith('http')
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Center(
                child: Text(_initials,
                    style: TextStyle(
                        color: color,
                        fontSize: size * 0.3,
                        fontWeight: FontWeight.w800)),
              ),
            )
          : Center(
              child: Text(_initials,
                  style: TextStyle(
                      color: color,
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w800)),
            ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.primaryColor,
    required this.fontFamily,
    required this.dark,
    required this.onBook,
  });

  final AgendaService service;
  final Color primaryColor;
  final String fontFamily;
  final bool dark;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? Colors.white : Colors.black87;
    final subColor = dark ? Colors.white54 : Colors.grey.shade600;
    final cardColor =
        dark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade50;
    final borderColor =
        dark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200;

    return InkWell(
      onTap: onBook,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.nombre,
                      style: _fs(fontFamily,
                          size: 15,
                          weight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 4),
                  Text('${service.duracionMin} min',
                      style: _fs(fontFamily, size: 13, color: subColor)),
                ],
              ),
            ),
            Text(
              '\$${service.precio.toStringAsFixed(0)}',
              style: _fs(fontFamily,
                  size: 16,
                  weight: FontWeight.w700,
                  color: primaryColor),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: subColor),
          ],
        ),
      ),
    );
  }
}

TextStyle _fs(String family, {double? size, FontWeight? weight, Color? color}) {
  try {
    return GoogleFonts.getFont(family,
        fontSize: size, fontWeight: weight, color: color);
  } catch (_) {
    return TextStyle(
        fontFamily: family, fontSize: size, fontWeight: weight, color: color);
  }
}
