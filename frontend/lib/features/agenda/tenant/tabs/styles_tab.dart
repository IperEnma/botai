// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/agenda_address.dart';
import '../../../../core/agenda_image_upload_prep_web.dart';
import '../../../../core/agenda_media_url.dart';
import '../../../../models/agenda/business.dart';
import '../../../../providers/agenda/agenda_api_provider.dart';
import '../../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../../providers/agenda/tenant/business_photos_provider.dart';
import '../../../../providers/agenda/tenant/businesses_provider.dart';
import '../../register/konecta_tokens.dart';
import '../../shared/k_button.dart';
import 'styles/banner_block.dart';
import 'styles/brand_style.dart';
import 'styles/color_block.dart';
import 'styles/font_block.dart';
import 'styles/logo_block.dart';
import 'styles/public_preview.dart';
import 'styles/works_block.dart';

const _kPreviewBreak = 1200.0;
const _kPreviewWidth = 380.0;

class StylesTab extends ConsumerStatefulWidget {
  const StylesTab({super.key, required this.tenantId, required this.business});

  final String tenantId;
  final Business business;

  @override
  ConsumerState<StylesTab> createState() => _StylesTabState();
}

class _StylesTabState extends ConsumerState<StylesTab> {
  late String _primary;
  late String _background;
  late String _font;
  String? _logoUrl;
  String? _bannerUrl;
  final _direccionCtrl = TextEditingController();

  bool _changed = false;
  bool _saving = false;
  bool _uploadingLogo = false;
  bool _uploadingBanner = false;
  String? _addressFormatError;
  AddressGeocodeResult? _addressGeocode;
  bool _addressValidating = false;
  Timer? _addressDebounce;
  int _addressGeocodeGeneration = 0;

  @override
  void initState() {
    super.initState();
    _hydrate(widget.business);
    _direccionCtrl.addListener(_handleDireccionChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanupCorruptMediaIfNeeded();
      _handleDireccionChange();
    });
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _direccionCtrl.removeListener(_handleDireccionChange);
    _direccionCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StylesTab old) {
    super.didUpdateWidget(old);
    if (!_changed && widget.business != old.business) {
      _hydrate(widget.business);
    } else {
      // Logo y banner se persisten por separado (al subir) — sincronizar igual.
      _logoUrl = sanitizeAgendaMediaUrl(widget.business.logoUrl) ?? _logoUrl;
      _bannerUrl = sanitizeAgendaMediaUrl(widget.business.bannerUrl) ?? _bannerUrl;
    }
  }

  void _hydrate(Business b) {
    _primary = (b.colorPrimario ?? '#3B2F63').toUpperCase();
    _background = (b.colorFondo ?? '#FBFAF7').toUpperCase();
    _font = b.fontFamily ?? 'Inter';
    _logoUrl = sanitizeAgendaMediaUrl(b.logoUrl);
    _bannerUrl = sanitizeAgendaMediaUrl(b.bannerUrl);
    _direccionCtrl.text = b.direccion ?? '';
  }

  String? get _direccionValue {
    final v = _direccionCtrl.text.trim();
    return v.isEmpty ? null : v;
  }

  void _handleDireccionChange() {
    _addressDebounce?.cancel();
    final value = _direccionCtrl.text;
    final formatError = AgendaAddressFormat.validate(value);

    if (value.trim() != (widget.business.direccion ?? '').trim()) {
      if (!_changed) setState(() => _changed = true);
    }

    setState(() {
      _addressFormatError = formatError;
      if (formatError != null || value.trim().isEmpty) {
        _addressGeocode = null;
        _addressValidating = false;
      }
    });

    if (formatError != null || value.trim().isEmpty) return;

    _addressDebounce = Timer(const Duration(milliseconds: 700), () {
      _runAddressGeocode(value.trim());
    });
  }

  Future<void> _runAddressGeocode(String address) async {
    final generation = ++_addressGeocodeGeneration;
    if (mounted) setState(() => _addressValidating = true);
    try {
      final result =
          await ref.read(agendaApiServiceProvider).geocodeAddress(address);
      if (!mounted || generation != _addressGeocodeGeneration) return;
      setState(() {
        _addressGeocode = result;
        _addressValidating = false;
      });
    } catch (_) {
      if (!mounted || generation != _addressGeocodeGeneration) return;
      setState(() {
        _addressGeocode = AddressGeocodeResult.notFound;
        _addressValidating = false;
      });
    }
  }

  void _setPrimary(String hex) {
    setState(() {
      _primary = hex;
      _changed = true;
    });
  }

  void _setBackground(String hex) {
    setState(() {
      _background = hex;
      _changed = true;
    });
  }

  void _setFont(String family) {
    setState(() {
      _font = family;
      _changed = true;
    });
  }

  void _invalidatePublicProfile() {
    final slug = widget.business.publicSlug;
    if (slug != null && slug.isNotEmpty) {
      ref.invalidate(publicBusinessBySlugProvider(slug));
    }
  }

  /// Repara banner/dirección intercambiados en BD o media inválida en logo/banner.
  Future<void> _cleanupCorruptMediaIfNeeded() async {
    if (!mounted) return;
    final b = widget.business;
    if (!b.needsFieldRepair && !b.hadInvalidMediaUrls) return;
    try {
      await ref.read(businessesProvider(widget.tenantId).notifier).update(
            businessId: b.id,
            nombre: b.nombre,
            descripcion: b.descripcion,
            searchTags: b.searchTags,
            logoUrl: b.logoUrl ?? '',
            bannerUrl: b.bannerUrl ?? '',
            colorPrimario: _primary,
            instagramUrl: b.instagramUrl,
            tiktokUrl: b.tiktokUrl,
            facebookUrl: b.facebookUrl,
            colorFondo: _background,
            fontFamily: _font,
            direccion: b.direccion,
          );
      if (mounted) {
        setState(() {
          _logoUrl = b.logoUrl;
          _bannerUrl = b.bannerUrl;
          _direccionCtrl.text = b.direccion ?? '';
        });
        _invalidatePublicProfile();
      }
    } catch (_) {
      // Silencioso: el usuario puede limpiar con Guardar.
    }
  }

  // ── Logo upload ────────────────────────────────────────────────────────────

  void _pickAndUploadLogo() {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((_) async {
      final file = input.files?.first;
      if (file == null) return;
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Máx. 5 MB.')),
          );
        }
        return;
      }
      setState(() => _uploadingLogo = true);
      try {
        final prepared = await prepareLogoUpload(file);

        final api = ref.read(agendaApiServiceProvider);
        final url = await api.uploadBusinessAvatar(
          businessId: widget.business.id,
          bytes: prepared.bytes,
          fileName: prepared.fileName,
        );

        if (!mounted) return;
        setState(() => _logoUrl = sanitizeAgendaMediaUrl(url) ?? url);
        try {
          await ref.read(businessesProvider(widget.tenantId).notifier).load();
        } catch (_) {
          // Upload OK; refresh de lista es best-effort.
        }
        _invalidatePublicProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logo actualizado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error al subir: $e')));
        }
      } finally {
        if (mounted) setState(() => _uploadingLogo = false);
      }
    });
  }

  // ── Banner upload ───────────────────────────────────────────────────────────

  void _pickAndUploadBanner() {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((_) async {
      final file = input.files?.first;
      if (file == null) return;
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Máx. 5 MB.')),
          );
        }
        return;
      }
      setState(() => _uploadingBanner = true);
      try {
        final prepared = await prepareBannerUpload(file);

        final api = ref.read(agendaApiServiceProvider);
        final url = await api.uploadBusinessBanner(
          businessId: widget.business.id,
          bytes: prepared.bytes,
          fileName: prepared.fileName,
        );

        if (!mounted) return;
        setState(() => _bannerUrl = sanitizeAgendaMediaUrl(url) ?? url);
        try {
          await ref.read(businessesProvider(widget.tenantId).notifier).load();
        } catch (_) {
          // Upload OK; refresh de lista es best-effort.
        }
        _invalidatePublicProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Portada actualizada')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error al subir: $e')));
        }
      } finally {
        if (mounted) setState(() => _uploadingBanner = false);
      }
    });
  }

  // ── Save styles ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final formatError = AgendaAddressFormat.validate(_direccionCtrl.text);
    if (formatError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatError)),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(businessesProvider(widget.tenantId).notifier).update(
            businessId: widget.business.id,
            nombre: widget.business.nombre,
            descripcion: widget.business.descripcion,
            searchTags: widget.business.searchTags,
            logoUrl: _logoUrl ?? '',
            colorPrimario: _primary,
            instagramUrl: widget.business.instagramUrl,
            tiktokUrl: widget.business.tiktokUrl,
            facebookUrl: widget.business.facebookUrl,
            colorFondo: _background,
            fontFamily: _font,
            direccion: _direccionValue,
            bannerUrl: _bannerUrl ?? '',
          );
      if (mounted) {
        setState(() => _changed = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Estilos guardados')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Photo dialog ───────────────────────────────────────────────────────────

  void _showAddPhotoDialog(({String tenantId, String businessId}) key) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KTokens.rMd)),
        title: Text('Agregar foto',
            style:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pegá la URL de la foto del trabajo realizado.',
              style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KTokens.ink,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final url = ctrl.text.trim();
              if (url.isEmpty) return;
              Navigator.of(ctx).pop();
              await ref
                  .read(businessPhotosProvider(key).notifier)
                  .addPhoto(url);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _kPreviewBreak;
    final photosKey =
        (tenantId: widget.tenantId, businessId: widget.business.id);
    final photosState = ref.watch(businessPhotosProvider(photosKey));
    final photoUrls =
        photosState.photos.map((p) => p.url).take(BrandStyle.maxPhotos).toList();

    final brand = BrandStyle(
      logoUrl: _logoUrl,
      primaryColor: _primary,
      backgroundColor: _background,
      fontFamily: _font,
      workPhotos: photoUrls,
    );

    final config = _ConfigColumn(
      brand: brand,
      logoUrl: _logoUrl,
      bannerUrl: _bannerUrl,
      direccionCtrl: _direccionCtrl,
      addressFormatError: _addressFormatError,
      addressGeocode: _addressGeocode,
      addressValidating: _addressValidating,
      isUploadingLogo: _uploadingLogo,
      isUploadingBanner: _uploadingBanner,
      isChanged: _changed,
      isSaving: _saving,
      isBusyPhotos: photosState.isSaving,
      photoUrls: photoUrls,
      onUploadLogo: _pickAndUploadLogo,
      onUploadBanner: _pickAndUploadBanner,
      onPrimaryChange: _setPrimary,
      onBackgroundChange: _setBackground,
      onFontChange: _setFont,
      onAddPhoto: () => _showAddPhotoDialog(photosKey),
      onDeletePhoto: (i) async {
        if (i >= photosState.photos.length) return;
        final photo = photosState.photos[i];
        await ref
            .read(businessPhotosProvider(photosKey).notifier)
            .deletePhoto(photo.id);
      },
      onSave: _save,
      onOpenPreview: isWide ? null : () => _openPreviewSheet(brand),
    );

    if (!isWide) {
      return Scaffold(
        backgroundColor: KTokens.bg,
        body: config,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: KTokens.ink,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.smartphone_rounded, size: 18),
          label: const Text('Previsualizar'),
          onPressed: () => _openPreviewSheet(brand),
        ),
      );
    }

    return Container(
      color: KTokens.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: config),
          Container(
            width: _kPreviewWidth,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F2EC),
              border:
                  Border(left: BorderSide(color: KTokens.border)),
            ),
            child: _PreviewColumn(brand: brand, business: widget.business),
          ),
        ],
      ),
    );
  }

  void _openPreviewSheet(BrandStyle brand) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF5F2EC),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: _PreviewColumn(
                brand: brand,
                business: widget.business,
                inSheet: true,
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Config column ────────────────────────────────────────────────────────────

class _ConfigColumn extends StatelessWidget {
  const _ConfigColumn({
    required this.brand,
    required this.logoUrl,
    required this.bannerUrl,
    required this.direccionCtrl,
    required this.addressFormatError,
    required this.addressGeocode,
    required this.addressValidating,
    required this.isUploadingLogo,
    required this.isUploadingBanner,
    required this.isChanged,
    required this.isSaving,
    required this.isBusyPhotos,
    required this.photoUrls,
    required this.onUploadLogo,
    required this.onUploadBanner,
    required this.onPrimaryChange,
    required this.onBackgroundChange,
    required this.onFontChange,
    required this.onAddPhoto,
    required this.onDeletePhoto,
    required this.onSave,
    required this.onOpenPreview,
  });

  final BrandStyle brand;
  final String? logoUrl;
  final String? bannerUrl;
  final TextEditingController direccionCtrl;
  final String? addressFormatError;
  final AddressGeocodeResult? addressGeocode;
  final bool addressValidating;
  final bool isUploadingLogo;
  final bool isUploadingBanner;
  final bool isChanged;
  final bool isSaving;
  final bool isBusyPhotos;
  final List<String> photoUrls;
  final VoidCallback onUploadLogo;
  final VoidCallback onUploadBanner;
  final ValueChanged<String> onPrimaryChange;
  final ValueChanged<String> onBackgroundChange;
  final ValueChanged<String> onFontChange;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onDeletePhoto;
  final VoidCallback onSave;
  final VoidCallback? onOpenPreview;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 36, 40, 100),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Estilos',
                style: KTokens.tDisplay,
              ),
              const SizedBox(height: 8),
              Text(
                'Así se ve tu marca al cliente cuando reserva. Los cambios se reflejan al instante en la vista previa.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: KTokens.inkMuted,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 32),

              // 4.1 Logo
              _Block(
                title: 'Logo del negocio',
                hint:
                    'Aparece en tu perfil público y en las confirmaciones. PNG, JPG o WEBP — máx. 5 MB.',
                child: LogoBlock(
                  logoUrl: logoUrl,
                  isUploading: isUploadingLogo,
                  onUpload: onUploadLogo,
                ),
              ),
              const _BlockDivider(),

              // 4.1b Imagen de portada (banner)
              _Block(
                title: 'Imagen de portada',
                hint:
                    'Banner que se muestra arriba de tu perfil público. PNG, JPG o WEBP — máx. 5 MB.',
                child: BannerBlock(
                  bannerUrl: bannerUrl,
                  isUploading: isUploadingBanner,
                  onUpload: onUploadBanner,
                ),
              ),
              const _BlockDivider(),

              // 4.1c Dirección
              _Block(
                title: 'Dirección',
                hint:
                    'Dirección completa, barrio o ciudad. Se muestra en tu perfil público; el mapa usa la mejor ubicación posible.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: direccionCtrl,
                      style: GoogleFonts.inter(fontSize: 14, color: KTokens.ink),
                      decoration: InputDecoration(
                        hintText: 'Av. Brasil 2847, Montevideo — o solo Pocitos, Montevideo',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: KTokens.inkPlaceholder,
                        ),
                        prefixIcon: const Icon(Icons.place_outlined,
                            size: 20, color: KTokens.inkSoft),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(KTokens.rMd),
                        ),
                        errorText: addressFormatError,
                      ),
                    ),
                    if (addressValidating) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KTokens.inkMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Buscando en el mapa…',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: KTokens.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ] else if (addressFormatError == null &&
                        direccionCtrl.text.trim().isNotEmpty &&
                        addressGeocode != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            addressGeocode!.found
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            size: 16,
                            color: addressGeocode!.found
                                ? const Color(0xFF16A34A)
                                : KTokens.inkMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              addressGeocode!.found
                                  ? AgendaAddressFormat.mapHintForPrecision(
                                      addressGeocode!.precision,
                                      direccionCtrl.text,
                                    )
                                  : 'No pudimos ubicarla en el mapa. Podés guardarla igual; el perfil mostrará la dirección sin miniatura.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: KTokens.inkMuted,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const _BlockDivider(),

              // 4.2 Color principal
              _Block(
                title: 'Color principal',
                hint:
                    'Define botones, acentos y el encabezado de tu perfil.',
                child: ColorBlock(
                  swatches: primaryPalette,
                  value: brand.primaryColor,
                  onChanged: onPrimaryChange,
                ),
              ),
              const _BlockDivider(),

              // 4.3 Color de fondo
              _Block(
                title: 'Color de fondo',
                hint:
                    'El lienzo detrás de tu perfil. Claro u oscuro según tu marca.',
                child: ColorBlock(
                  swatches: bgPalette,
                  value: brand.backgroundColor,
                  onChanged: onBackgroundChange,
                  bordered: true,
                ),
              ),
              const _BlockDivider(),

              // 4.4 Tipografía
              _Block(
                title: 'Tipografía',
                hint:
                    'La fuente de tu perfil público. Se aplica a títulos y textos.',
                child: FontBlock(
                  fonts: fontFamilies,
                  value: brand.fontFamily,
                  onChanged: onFontChange,
                ),
              ),
              const _BlockDivider(),

              // 4.5 Trabajos
              _Block(
                title: 'Trabajos',
                hint:
                    'Mostrá tus mejores resultados — hasta ${BrandStyle.maxPhotos} fotos. Se ven en 2 columnas en el celular y 4 en escritorio.',
                child: WorksBlock(
                  photoUrls: photoUrls,
                  busy: isBusyPhotos,
                  onAdd: onAddPhoto,
                  onDelete: onDeletePhoto,
                ),
              ),

              if (isChanged) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    KButton.primary(
                      label: 'Guardar cambios',
                      icon: Icons.check_rounded,
                      loading: isSaving,
                      onPressed: addressFormatError == null ? onSave : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tenés cambios sin guardar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: KTokens.inkMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.hint,
    required this.child,
  });

  final String title;
  final String hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: KTokens.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: KTokens.inkSoft,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _BlockDivider extends StatelessWidget {
  const _BlockDivider();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Divider(height: 1, color: KTokens.border),
    );
  }
}

// ─── Preview column ───────────────────────────────────────────────────────────

class _PreviewColumn extends StatelessWidget {
  const _PreviewColumn({
    required this.brand,
    required this.business,
    this.inSheet = false,
  });

  final BrandStyle brand;
  final Business business;
  final bool inSheet;

  @override
  Widget build(BuildContext context) {
    final subtitle = (business.descripcion?.split('\n').first.trim() ?? '');

    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VISTA PREVIA',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            letterSpacing: 1.4,
            color: KTokens.inkSoft,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tu perfil público',
          style: KTokens.tHero,
        ),
        const SizedBox(height: 20),
        PublicPreview(
          businessName: business.nombre,
          subtitle: subtitle.isEmpty
              ? (business.categorias.isNotEmpty
                  ? business.categorias.first
                  : 'Negocio')
              : subtitle,
          style: brand,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 13, color: KTokens.inkPlaceholder),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Esta es la cara pública de tu negocio. El enlace lo compartís por WhatsApp, Instagram o lo usa tu bot.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: KTokens.inkPlaceholder,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    if (inSheet) return card;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      child: card,
    );
  }
}
