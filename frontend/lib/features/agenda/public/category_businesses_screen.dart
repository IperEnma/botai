import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/agenda/public/public_categories_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../../../widgets/agenda/business_summary_card.dart';

const _kPrimary     = Color(0xFF6366F1);
const _kPrimaryDark = Color(0xFF4F46E5);
const _kSurface     = Color(0xFFF8FAFC);

class CategoryBusinessesScreen extends ConsumerWidget {
  const CategoryBusinessesScreen({
    super.key,
    required this.slug,
    required this.tenantId,
  });

  final String slug;
  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(
      businessesByCategoryProvider((slug: slug, tenantId: tenantId)),
    );

    return Scaffold(
      backgroundColor: _kSurface,
      body: Column(
        children: [
          // ── Hero degradado ─────────────────────────────────────────────
          _CategoryHero(slug: slug),

          // ── Contenido ─────────────────────────────────────────────────
          Expanded(
            child: asyncList.when(
              loading: () => const AgendaLoadingView(),
              error: (e, _) => AgendaErrorView(
                message: 'No se pudo cargar la categoría: $e',
                onRetry: () => ref.refresh(
                  businessesByCategoryProvider((slug: slug, tenantId: tenantId)),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const AgendaEmptyState(
                    icon: Icons.search_off,
                    title: 'No hay negocios en esta categoría',
                    subtitle: 'Volvé más tarde o explorá otras categorías.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final b = list[index];
                    return BusinessSummaryCard(
                      business: b,
                      onTap: () {
                        final path = b.profilePath;
                        if (path != null) context.go(path);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero de categoría ─────────────────────────────────────────────────────────

class _CategoryHero extends StatelessWidget {
  const _CategoryHero({required this.slug});

  final String slug;

  IconData _iconForSlug() {
    switch (slug.toLowerCase()) {
      case 'peluqueria':
      case 'barberia':
        return Icons.content_cut;
      case 'gym':
      case 'gimnasio':
      case 'fitness':
        return Icons.fitness_center;
      case 'medico':
      case 'salud':
        return Icons.local_hospital_outlined;
      case 'spa':
      case 'belleza':
      case 'unas':
        return Icons.spa_outlined;
      case 'restaurante':
      case 'gastronomia':
        return Icons.restaurant_outlined;
      default:
        return Icons.store_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        24,
      ),
      child: Row(
        children: [
          // Botón back
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/agenda/search'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          // Ícono de categoría
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconForSlug(), color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slug[0].toUpperCase() + slug.substring(1),
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  'Negocios disponibles',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
