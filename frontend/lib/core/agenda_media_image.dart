import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'agenda_media_url.dart';

/// Imagen remota de Agenda (logo, banner, avatar) con URL resuelta al backend actual.
///
/// - **Web:** [Image.network] → `<img>` nativo + cache HTTP del navegador (más eficiente).
/// - **Mobile:** [CachedNetworkImage] con cache en disco + decode acotado al tamaño en pantalla.
class AgendaMediaImage extends StatelessWidget {
  const AgendaMediaImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.errorWidget,
  });

  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  /// Ancho máximo de decode en px lógicos (prioridad sobre [width] × DPR).
  final int? cacheWidth;
  /// Alto máximo de decode en px lógicos (prioridad sobre [height] × DPR).
  final int? cacheHeight;
  final Widget? errorWidget;

  (int?, int?) _decodeSize(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final w = cacheWidth ?? (width != null ? (width! * dpr).round() : null);
    final h = cacheHeight ?? (height != null ? (height! * dpr).round() : null);
    return (w, h);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAgendaMediaUrl(url);
    if (resolved == null) {
      return errorWidget ?? const SizedBox.shrink();
    }

    final (memW, memH) = _decodeSize(context);
    final onError = errorWidget ?? const SizedBox.shrink();

    if (kIsWeb) {
      return Image.network(
        resolved,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        cacheWidth: memW,
        cacheHeight: memH,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => onError,
      );
    }

    return CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      memCacheWidth: memW,
      memCacheHeight: memH,
      maxWidthDiskCache: memW,
      maxHeightDiskCache: memH,
      fadeInDuration: Duration.zero,
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => onError,
    );
  }
}
