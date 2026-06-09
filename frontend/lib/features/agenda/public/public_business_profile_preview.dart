import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/business_hours.dart';
import '../../../models/agenda/business_photo.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../tenant/tabs/styles/brand_style.dart';
import 'public_business_profile_screen.dart';

/// Altura simulada de barra de estado en el marco móvil de la vista previa.
const kPublicProfilePreviewStatusBar = 44.0;

/// Vista previa en Estilos: mismo widget que `/reservar/{slug}` con estilos en borrador.
class PublicBusinessProfilePreview extends ConsumerWidget {
  const PublicBusinessProfilePreview({
    super.key,
    required this.business,
    required this.brand,
    this.bannerUrl,
    this.direccion,
    this.tenantServices = const [],
    this.tenantStaff = const [],
  });

  final Business business;
  final BrandStyle brand;
  final String? bannerUrl;
  final String? direccion;
  final List<AgendaService> tenantServices;
  final List<StaffMember> tenantStaff;

  static Business mergeDraft({
    required Business business,
    required BrandStyle brand,
    String? bannerUrl,
    String? direccion,
  }) {
    final addr = direccion?.trim();
    return business.copyWith(
      logoUrl: brand.logoUrl,
      colorPrimario: brand.primaryColor,
      colorFondo: brand.backgroundColor,
      colorTarjeta: brand.cardColor,
      fontFamily: brand.fontFamily,
      bannerUrl: bannerUrl,
      direccion: addr == null || addr.isEmpty ? null : addr,
    );
  }

  static List<BusinessPhoto> photosFromBrand(BrandStyle brand, Business business) {
    return brand.workPhotos
        .asMap()
        .entries
        .map(
          (e) => BusinessPhoto(
            id: 'preview-${e.key}',
            businessId: business.id,
            url: e.value,
            orden: e.key,
          ),
        )
        .toList();
  }

  /// Firma del borrador — fuerza recrear providers cuando cambian estilos en vivo.
  static int draftRevisionKey({
    required BrandStyle brand,
    String? bannerUrl,
    String? direccion,
  }) {
    return Object.hash(
      brand.primaryColor.toUpperCase(),
      brand.backgroundColor.toUpperCase(),
      brand.cardColor.toUpperCase(),
      brand.fontFamily,
      brand.logoUrl,
      bannerUrl,
      direccion?.trim(),
      Object.hashAll(brand.workPhotos),
    );
  }

  /// Servicios para la preview: reales del tenant o ejemplos si aún no hay.
  static PreviewContentBundle contentBundle({
    required Business business,
    List<AgendaService> tenantServices = const [],
    List<StaffMember> tenantStaff = const [],
  }) {
    final activeServices =
        tenantServices.where((s) => s.activo).take(4).toList();
    final activeStaff =
        tenantStaff.where((s) => s.activo).take(4).toList();

    final services = activeServices.isNotEmpty
        ? activeServices
        : _sampleServices(business.id);
    final staff =
        activeStaff.isNotEmpty ? activeStaff : _sampleStaff(business.id);

    return PreviewContentBundle(
      services: services,
      staff: staff,
      usesSampleServices: activeServices.isEmpty,
      usesSampleStaff: activeStaff.isEmpty,
    );
  }

  static List<AgendaService> _sampleServices(String businessId) => [
        AgendaService(
          id: 'preview-svc-1',
          businessId: businessId,
          nombre: 'Servicio principal',
          descripcion: 'Duración estimada 45 min',
          duracionMin: 45,
          precio: 28,
          activo: true,
        ),
        AgendaService(
          id: 'preview-svc-2',
          businessId: businessId,
          nombre: 'Servicio express',
          duracionMin: 30,
          precio: 18,
          activo: true,
        ),
        AgendaService(
          id: 'preview-svc-3',
          businessId: businessId,
          nombre: 'Paquete completo',
          descripcion: 'La opción más elegida',
          duracionMin: 60,
          precio: 42,
          activo: true,
        ),
      ];

  static List<StaffMember> _sampleStaff(String businessId) => [
        StaffMember(
          id: 'preview-staff-1',
          businessId: businessId,
          nombre: 'María G.',
          rol: 'Profesional',
          activo: true,
          status: 'ACTIVO',
          rating: 4.9,
          reviewCount: 32,
        ),
        StaffMember(
          id: 'preview-staff-2',
          businessId: businessId,
          nombre: 'Luis P.',
          rol: 'Especialista',
          activo: true,
          status: 'ACTIVO',
          rating: 4.7,
          reviewCount: 18,
        ),
      ];

  static List<BusinessHours> _sampleHours(String businessId) => List.generate(
        7,
        (dia) {
          final closed = dia == 6;
          return BusinessHours(
            id: 'preview-hours-$dia',
            businessId: businessId,
            diaSemana: dia,
            apertura: closed ? null : '09:00',
            cierre: closed ? null : '18:00',
            cerrado: closed,
          );
        },
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slug = business.publicSlug?.trim();
    if (slug == null || slug.isEmpty) {
      return const _PreviewUnavailable(
        message:
            'Tu negocio aún no tiene enlace público. Guardá los datos del negocio para generar el slug.',
      );
    }

    final previewBusiness = mergeDraft(
      business: business,
      brand: brand,
      bannerUrl: bannerUrl,
      direccion: direccion,
    );
    final previewPhotos = photosFromBrand(brand, business);
    final bundle = contentBundle(
      business: previewBusiness,
      tenantServices: tenantServices,
      tenantStaff: tenantStaff,
    );
    final previewHours = _sampleHours(previewBusiness.id);
    final draftKey = draftRevisionKey(
      brand: brand,
      bannerUrl: bannerUrl,
      direccion: direccion,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w < 1 || h < 1) return const SizedBox.shrink();

        final mq = MediaQuery.of(context);
        final frame = MediaQuery(
          data: mq.copyWith(
            size: Size(w, h),
            padding: const EdgeInsets.only(top: kPublicProfilePreviewStatusBar),
            viewPadding: const EdgeInsets.only(top: kPublicProfilePreviewStatusBar),
          ),
          child: ProviderScope(
            key: ValueKey(draftKey),
            overrides: [
              publicBusinessBySlugProvider.overrideWith(
                (ref, _) async => previewBusiness,
              ),
              publicPhotosBySlugProvider.overrideWith(
                (ref, _) async => previewPhotos,
              ),
              publicBusinessServicesBySlugProvider.overrideWith(
                (ref, _) async => bundle.services,
              ),
              publicStaffBySlugProvider.overrideWith(
                (ref, _) async => bundle.staff,
              ),
              publicHoursBySlugProvider.overrideWith(
                (ref, _) async => previewHours,
              ),
            ],
            child: PublicBusinessProfileScreen(
              key: ValueKey(draftKey),
              slug: slug,
              preview: true,
            ),
          ),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x1A000000)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: frame,
          ),
        );
      },
    );
  }
}

/// Datos mostrados en la preview y si son de ejemplo.
class PreviewContentBundle {
  const PreviewContentBundle({
    required this.services,
    required this.staff,
    required this.usesSampleServices,
    required this.usesSampleStaff,
  });

  final List<AgendaService> services;
  final List<StaffMember> staff;
  final bool usesSampleServices;
  final bool usesSampleStaff;

  bool get usesAnySample => usesSampleServices || usesSampleStaff;
}

class _PreviewUnavailable extends StatelessWidget {
  const _PreviewUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF64748B),
          height: 1.45,
        ),
      ),
    );
  }
}
