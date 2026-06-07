import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'agenda_media_url.dart';

/// Imagen remota de Agenda (logo, banner, avatar) con URL resuelta al backend actual.
class AgendaMediaImage extends StatelessWidget {
  const AgendaMediaImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.errorWidget,
  });

  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAgendaMediaUrl(url);
    if (resolved == null) {
      return errorWidget ?? const SizedBox.shrink();
    }

    final loading = Container(
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );

    // Web: mismo patrón que el panel (Image.network → <img>, sin CORS para mostrar).
    // CachedNetworkImage en web usa fetch y falla si /uploads no expone CORS.
    if (kIsWeb) {
      return Image.network(
        resolved,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : loading,
        errorBuilder: (_, _, _) => errorWidget ?? const SizedBox.shrink(),
      );
    }

    return CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => loading,
      errorWidget: (_, _, _) => errorWidget ?? const SizedBox.shrink(),
    );
  }
}
