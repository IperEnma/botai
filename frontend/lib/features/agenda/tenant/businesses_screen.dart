import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/navigation/agenda_tenant_nav.dart';
import '../../../models/agenda/agenda_search_tag.dart';
import '../../../models/agenda/business.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import 'widgets/business_form_dialog.dart';

const _kPrimary = Color(0xFF6366F1);
const _kSurface = Color(0xFFF8FAFC);
const _kDark    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);

class BusinessesScreen extends ConsumerWidget {
  const BusinessesScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(businessesProvider(tenantId));

    if (state.isLoading) return const AgendaLoadingView();
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(businessesProvider(tenantId).notifier).load(),
      );
    }

    return Scaffold(
      backgroundColor: _kSurface,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'businesses_fab',
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nuevo negocio',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.white),
        ),
        onPressed: () async {
          final result = await showDialog<BusinessFormResult>(
            context: context,
            builder: (_) => const BusinessFormDialog(),
          );
          if (result == null || !context.mounted) return;
          try {
            await ref.read(businessesProvider(tenantId).notifier).create(
                  nombre: result.nombre,
                  descripcion: result.descripcion,
                  searchTags: result.profileLabels
                      .map(AgendaSearchTag.profile)
                      .toList(),
                );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
      body: state.items.isEmpty
          ? const AgendaEmptyState(
              icon: Icons.store_mall_directory_outlined,
              title: 'Sin negocios',
              subtitle: 'Creá el primer negocio con el botón +',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final b = state.items[i];
                return _BusinessCard(
                  business: b,
                  onTap: () => navigateAgendaTenantBusiness(
                    context,
                    ref,
                    b.id,
                  ),
                );
              },
            ),
    );
  }
}


class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.business, required this.onTap});

  final Business business;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = business.nombre.substring(0, 1).toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [

            // 🟦 CARD
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [

                  // 🔵 FRANJA
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),

                  // 📝 CONTENIDO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [

                        Text(
                          business.nombre,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _kDark,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          business.descripcion ?? '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _kMuted,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: business.categorias.map((c) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _kPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🟡 LOGO REDONDO (CLAVE)
            Positioned(
              top: 70,
              left: 20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.15),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 🔴 BADGE
            if (business.activo)
              Positioned(
                top: 20,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Activo',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}