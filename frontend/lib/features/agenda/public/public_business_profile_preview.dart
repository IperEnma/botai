import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/business.dart';
import '../../../models/agenda/business_photo.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../tenant/tabs/styles/brand_style.dart';
import 'public_business_profile_screen.dart';

/// Vista previa en Estilos: mismo widget que `/reservar/{slug}` con estilos en borrador.
class PublicBusinessProfilePreview extends ConsumerWidget {
  const PublicBusinessProfilePreview({
    super.key,
    required this.business,
    required this.brand,
    this.bannerUrl,
    this.direccion,
  });

  final Business business;
  final BrandStyle brand;
  final String? bannerUrl;
  final String? direccion;

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ProviderScope(
        overrides: [
          publicBusinessBySlugProvider.overrideWith(
            (ref, _) async => previewBusiness,
          ),
          publicPhotosBySlugProvider.overrideWith(
            (ref, _) async => previewPhotos,
          ),
        ],
        child: PublicBusinessProfileScreen(slug: slug, preview: true),
      ),
    );
  }
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
