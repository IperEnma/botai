import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'agenda_media_url.dart';

/// Imagen remota de Agenda (logo, banner, avatar) con URL resuelta al backend actual.
///
/// - **Web:** [Image.network] → `<img>` nativo + cache HTTP del navegador.
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
    this.expand = false,
    this.errorWidget,
  });

  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  /// Ocupa todo el espacio del padre (banner hero). Evita `double.infinity` en web.
  final bool expand;
  final Widget? errorWidget;

  (int?, int?) _decodeSize(BuildContext context) {
    if (kIsWeb) return (null, null);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final w = cacheWidth ?? (width != null ? (width! * dpr).round() : null);
    final h = cacheHeight ?? (height != null ? (height! * dpr).round() : null);
    return (w, h);
  }

  Widget _wrap(Widget child) {
    if (expand) {
      return SizedBox.expand(child: child);
    }
    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAgendaMediaUrl(url);
    if (resolved == null) {
      return _wrap(errorWidget ?? const SizedBox.shrink());
    }

    final (memW, memH) = _decodeSize(context);
    final onError = errorWidget ?? const SizedBox.shrink();

    if (kIsWeb) {
      return _wrap(
        Image.network(
          resolved,
          fit: fit,
          alignment: alignment,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => onError,
        ),
      );
    }

    return _wrap(
      CachedNetworkImage(
        imageUrl: resolved,
        fit: fit,
        alignment: alignment,
        memCacheWidth: memW,
        memCacheHeight: memH,
        maxWidthDiskCache: memW,
        maxHeightDiskCache: memH,
        fadeInDuration: Duration.zero,
        placeholder: (_, _) => const SizedBox.shrink(),
        errorWidget: (_, _, _) => onError,
      ),
    );
  }
}
