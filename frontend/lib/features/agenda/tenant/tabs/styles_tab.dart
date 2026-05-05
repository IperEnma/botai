// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/business.dart';
import '../../../../providers/agenda/agenda_api_provider.dart';
import '../../../../providers/agenda/tenant/businesses_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Font families
// ─────────────────────────────────────────────────────────────────────────────

const _fonts = [
  'Roboto',
  'Montserrat',
  'Poppins',
  'Lato',
  'Open Sans',
  'Oswald',
  'Raleway',
  'Playfair Display',
];

TextStyle _fontStyle(String family,
    {double? size, FontWeight? weight, Color? color}) {
  try {
    return GoogleFonts.getFont(family,
        fontSize: size, fontWeight: weight, color: color);
  } catch (_) {
    return TextStyle(
        fontFamily: family, fontSize: size, fontWeight: weight, color: color);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Color palettes
// ─────────────────────────────────────────────────────────────────────────────

const _primaryPalette = [
  Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899),
  Color(0xFF14B8A6), Color(0xFF22C55E), Color(0xFFF59E0B),
  Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFF84CC16),
  Color(0xFF0EA5E9), Color(0xFFF97316), Color(0xFF64748B),
];

const _bgPalette = [
  Color(0xFFFFFFFF),
  Color(0xFFF8FAFC),
  Color(0xFFF1F5F9),
  Color(0xFF1E293B),
  Color(0xFF0F172A),
  Color(0xFF111827),
  Color(0xFFFFF7ED),
  Color(0xFFF0FDF4),
  Color(0xFFEFF6FF),
  Color(0xFFFDF4FF),
];

// ─────────────────────────────────────────────────────────────────────────────
// StylesTab
// ─────────────────────────────────────────────────────────────────────────────

class StylesTab extends ConsumerStatefulWidget {
  const StylesTab({super.key, required this.tenantId, required this.business});

  final String tenantId;
  final Business business;

  @override
  ConsumerState<StylesTab> createState() => _StylesTabState();
}

class _StylesTabState extends ConsumerState<StylesTab> {
  late String? _colorPrimario;
  late String? _colorFondo;
  late String? _fontFamily;
  bool _changed = false;
  bool _saving = false;
  bool _uploadingAvatar = false;

  String? _previewLogoUrl;

  @override
  void initState() {
    super.initState();
    _colorPrimario = widget.business.colorPrimario;
    _colorFondo = widget.business.colorFondo;
    _fontFamily = widget.business.fontFamily ?? 'Roboto';
    _previewLogoUrl = widget.business.logoUrl;
  }

  @override
  void didUpdateWidget(StylesTab old) {
    super.didUpdateWidget(old);
    if (!_changed) {
      _colorPrimario = widget.business.colorPrimario;
      _colorFondo = widget.business.colorFondo;
      _fontFamily = widget.business.fontFamily ?? 'Roboto';
    }
    _previewLogoUrl = widget.business.logoUrl;
  }

  Color get _primaryColor {
    if (_colorPrimario == null) return const Color(0xFF6366F1);
    final val =
        int.tryParse('FF${_colorPrimario!.replaceAll('#', '')}', radix: 16);
    return val != null ? Color(val) : const Color(0xFF6366F1);
  }

  Color get _bgColor {
    if (_colorFondo == null) return Colors.white;
    final val =
        int.tryParse('FF${_colorFondo!.replaceAll('#', '')}', radix: 16);
    return val != null ? Color(val) : Colors.white;
  }

  bool get _bgIsDark => _bgColor.computeLuminance() < 0.4;

  String _colorToHex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  // ── Avatar upload ──────────────────────────────────────────────────────────

  void _pickAndUploadAvatar() {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((_) async {
      final file = input.files?.first;
      if (file == null) return;
      setState(() => _uploadingAvatar = true);
      try {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoad.first;
        final dataUrl = reader.result as String;
        final comma = dataUrl.indexOf(',');
        final bytes = base64.decode(dataUrl.substring(comma + 1));

        final api = ref.read(agendaApiServiceProvider);
        final url = await api.uploadBusinessAvatar(
          tenantId: widget.tenantId,
          businessId: widget.business.id,
          bytes: bytes,
          fileName: file.name,
        );

        await ref.read(businessesProvider(widget.tenantId).notifier).update(
              businessId: widget.business.id,
              nombre: widget.business.nombre,
              descripcion: widget.business.descripcion,
              searchTags: widget.business.searchTags,
              logoUrl: url,
              colorPrimario: _colorPrimario,
              instagramUrl: widget.business.instagramUrl,
              tiktokUrl: widget.business.tiktokUrl,
              facebookUrl: widget.business.facebookUrl,
              colorFondo: _colorFondo,
              fontFamily: _fontFamily,
            );
        if (mounted) {
          setState(() => _previewLogoUrl = url);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Avatar actualizado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al subir imagen: $e')));
        }
      } finally {
        if (mounted) setState(() => _uploadingAvatar = false);
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
            logoUrl: widget.business.logoUrl,
            colorPrimario: _colorPrimario,
            instagramUrl: widget.business.instagramUrl,
            tiktokUrl: widget.business.tiktokUrl,
            facebookUrl: widget.business.facebookUrl,
            colorFondo: _colorFondo,
            fontFamily: _fontFamily,
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final business = widget.business;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Vista previa ──────────────────────────────────────────────────
          _SectionHeader('Vista previa'),
          const SizedBox(height: 4),
          Text(
            'Así verá el usuario final tu perfil de negocio',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          _BusinessPreviewCard(
            business: business,
            previewLogoUrl: _previewLogoUrl,
            bgColor: _bgColor,
            primaryColor: _primaryColor,
            fontFamily: _fontFamily ?? 'Roboto',
            bgIsDark: _bgIsDark,
          ),

          const SizedBox(height: 36),
          const Divider(),
          const SizedBox(height: 24),

          // ── Avatar ────────────────────────────────────────────────────────
          _SectionHeader('Imagen de avatar'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarPreview(
                logoUrl: _previewLogoUrl,
                nombre: business.nombre,
                color: _primaryColor,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subí una imagen desde tu dispositivo (PNG, JPG, WEBP — máx. 5 MB)',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      icon: _uploadingAvatar
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.upload_outlined, size: 18),
                      label:
                          Text(_uploadingAvatar ? 'Subiendo…' : 'Subir imagen'),
                      onPressed:
                          _uploadingAvatar ? null : _pickAndUploadAvatar,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 36),
          const Divider(),
          const SizedBox(height: 24),

          // ── Color principal ───────────────────────────────────────────────
          _SectionHeader('Color principal'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _primaryPalette)
                _ColorSwatch(
                  color: c,
                  selected: _colorPrimario == _colorToHex(c),
                  onTap: () => setState(() {
                    _colorPrimario = _colorToHex(c);
                    _changed = true;
                  }),
                ),
              _HexColorInput(
                current: _colorPrimario,
                onChanged: (hex) => setState(() {
                  _colorPrimario = hex;
                  _changed = true;
                }),
              ),
            ],
          ),
          if (_colorPrimario != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_colorPrimario!,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _colorPrimario = null;
                    _changed = true;
                  }),
                  child: const Text('Quitar color'),
                ),
              ],
            ),
          ],

          const SizedBox(height: 36),
          const Divider(),
          const SizedBox(height: 24),

          // ── Color de fondo ────────────────────────────────────────────────
          _SectionHeader('Color de fondo'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _bgPalette)
                _BgSwatch(
                  color: c,
                  selected: _colorFondo == _colorToHex(c),
                  onTap: () => setState(() {
                    _colorFondo = _colorToHex(c);
                    _changed = true;
                  }),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Predeterminado'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _colorFondo == null
                    ? null
                    : () => setState(() {
                          _colorFondo = null;
                          _changed = true;
                        }),
              ),
            ],
          ),
          if (_colorFondo != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_colorFondo!,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              ],
            ),
          ],

          const SizedBox(height: 36),
          const Divider(),
          const SizedBox(height: 24),

          // ── Tipografía ────────────────────────────────────────────────────
          _SectionHeader('Tipografía'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final font in _fonts)
                _FontChip(
                  family: font,
                  selected: (_fontFamily ?? 'Roboto') == font,
                  onTap: () => setState(() {
                    _fontFamily = font;
                    _changed = true;
                  }),
                ),
            ],
          ),

          const SizedBox(height: 32),

          if (_changed)
            FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_saving ? 'Guardando…' : 'Guardar estilos'),
              onPressed: _saving ? null : _save,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Business preview card
// ─────────────────────────────────────────────────────────────────────────────

class _BusinessPreviewCard extends StatelessWidget {
  const _BusinessPreviewCard({
    required this.business,
    required this.previewLogoUrl,
    required this.bgColor,
    required this.primaryColor,
    required this.fontFamily,
    required this.bgIsDark,
  });

  final Business business;
  final String? previewLogoUrl;
  final Color bgColor;
  final Color primaryColor;
  final String fontFamily;
  final bool bgIsDark;

  @override
  Widget build(BuildContext context) {
    final textColor = bgIsDark ? Colors.white : Colors.black87;
    final subColor = bgIsDark ? Colors.white70 : Colors.black54;

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -36),
            child: Column(
              children: [
                _AvatarPreview(
                  logoUrl: previewLogoUrl,
                  nombre: business.nombre,
                  color: primaryColor,
                  size: 72,
                  borderColor: bgColor,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    business.nombre,
                    textAlign: TextAlign.center,
                    style: _fontStyle(fontFamily,
                        size: 20,
                        weight: FontWeight.w700,
                        color: textColor),
                  ),
                ),
                if (business.descripcion != null &&
                    business.descripcion!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Text(
                      business.descripcion!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _fontStyle(fontFamily, size: 13, color: subColor),
                    ),
                  ),
                const SizedBox(height: 12),
                if (business.categorias.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final cat in business.categorias.take(3))
                        Chip(
                          label: Text(cat,
                              style: _fontStyle(fontFamily,
                                  size: 11, color: primaryColor)),
                          backgroundColor:
                              primaryColor.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Reservar turno',
                        style: _fontStyle(fontFamily,
                            size: 14,
                            weight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
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
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return nombre.substring(0, nombre.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final border = borderColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: border != null
            ? Border.all(color: border, width: 3)
            : Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
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

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(
      {required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}

class _HexColorInput extends StatefulWidget {
  const _HexColorInput({required this.current, required this.onChanged});
  final String? current;
  final ValueChanged<String> onChanged;

  @override
  State<_HexColorInput> createState() => _HexColorInputState();
}

class _HexColorInputState extends State<_HexColorInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.current?.replaceAll('#', '') ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 36,
      child: TextField(
        controller: _ctrl,
        maxLength: 6,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
        ],
        decoration: const InputDecoration(
          prefixText: '#',
          hintText: 'HEX',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          counterText: '',
        ),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        onChanged: (v) {
          if (v.length == 6) widget.onChanged('#${v.toUpperCase()}');
        },
      ),
    );
  }
}

class _BgSwatch extends StatelessWidget {
  const _BgSwatch(
      {required this.color, required this.selected, required this.onTap});
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : Colors.grey.shade300,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [const BoxShadow(color: Color(0x446366F1), blurRadius: 8)]
              : null,
        ),
        child: selected
            ? Icon(Icons.check,
                size: 18,
                color: color.computeLuminance() < 0.5
                    ? Colors.white
                    : Colors.black54)
            : null,
      ),
    );
  }
}

class _FontChip extends StatelessWidget {
  const _FontChip(
      {required this.family, required this.selected, required this.onTap});
  final String family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF6366F1)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          family,
          style: _fontStyle(family,
              size: 14, color: selected ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      );
}
