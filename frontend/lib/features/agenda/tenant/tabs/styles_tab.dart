// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/business.dart';
import '../../../../providers/agenda/agenda_api_provider.dart';
import '../../../../providers/agenda/tenant/business_photos_provider.dart';
import '../../../../providers/agenda/tenant/businesses_provider.dart';
import '../../register/konecta_tokens.dart';
import '../../shared/k_button.dart';
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

  bool _changed = false;
  bool _saving = false;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _hydrate(widget.business);
  }

  @override
  void didUpdateWidget(StylesTab old) {
    super.didUpdateWidget(old);
    if (!_changed && widget.business != old.business) {
      _hydrate(widget.business);
    } else {
      // Logo se persiste por separado (al subir) — sincronizar igual.
      _logoUrl = widget.business.logoUrl ?? _logoUrl;
    }
  }

  void _hydrate(Business b) {
    _primary = (b.colorPrimario ?? '#3B2F63').toUpperCase();
    _background = (b.colorFondo ?? '#FBFAF7').toUpperCase();
    _font = b.fontFamily ?? 'Inter';
    _logoUrl = b.logoUrl;
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
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoad.first;
        final dataUrl = reader.result as String;
        final comma = dataUrl.indexOf(',');
        final bytes = base64.decode(dataUrl.substring(comma + 1));

        final api = ref.read(agendaApiServiceProvider);
        final url = await api.uploadBusinessAvatar(
          businessId: widget.business.id,
          bytes: bytes,
          fileName: file.name,
        );

        // Persistimos el logo enseguida (igual que el flow actual).
        await ref.read(businessesProvider(widget.tenantId).notifier).update(
              businessId: widget.business.id,
              nombre: widget.business.nombre,
              descripcion: widget.business.descripcion,
              searchTags: widget.business.searchTags,
              logoUrl: url,
              colorPrimario: _primary,
              instagramUrl: widget.business.instagramUrl,
              tiktokUrl: widget.business.tiktokUrl,
              facebookUrl: widget.business.facebookUrl,
              colorFondo: _background,
              fontFamily: _font,
            );
        if (mounted) {
          setState(() => _logoUrl = url);
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

  // ── Save styles ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(businessesProvider(widget.tenantId).notifier).update(
            businessId: widget.business.id,
            nombre: widget.business.nombre,
            descripcion: widget.business.descripcion,
            searchTags: widget.business.searchTags,
            logoUrl: _logoUrl,
            colorPrimario: _primary,
            instagramUrl: widget.business.instagramUrl,
            tiktokUrl: widget.business.tiktokUrl,
            facebookUrl: widget.business.facebookUrl,
            colorFondo: _background,
            fontFamily: _font,
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
      isUploadingLogo: _uploadingLogo,
      isChanged: _changed,
      isSaving: _saving,
      isBusyPhotos: photosState.isSaving,
      photoUrls: photoUrls,
      onUploadLogo: _pickAndUploadLogo,
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
    required this.isUploadingLogo,
    required this.isChanged,
    required this.isSaving,
    required this.isBusyPhotos,
    required this.photoUrls,
    required this.onUploadLogo,
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
  final bool isUploadingLogo;
  final bool isChanged;
  final bool isSaving;
  final bool isBusyPhotos;
  final List<String> photoUrls;
  final VoidCallback onUploadLogo;
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
                'PERSONALIZACIÓN',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: KTokens.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
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
                      onPressed: onSave,
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
