import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'config.dart';

/// URL pública absoluta del perfil `/reservar/:slug` (con query `company` si aplica).
String buildPublicBusinessProfileUrl(BuildContext context, String slug) {
  final uri = GoRouterState.of(context).uri;
  final path = uri.queryParameters.isEmpty
      ? '/reservar/$slug'
      : '/reservar/$slug?${uri.queryParameters.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';

  final configured = AppConfig.publicAppBaseUrl;
  if (configured != null) {
    return '$configured$path';
  }

  if (kIsWeb) {
    final origin = Uri.base.origin;
    if (origin.isNotEmpty && origin != 'null') {
      return '$origin$path';
    }
  }

  final origin = Uri.base.origin;
  if (origin.isNotEmpty && origin != 'null') {
    return '$origin$path';
  }

  return path;
}

/// Origen del botón para el popover de compartir en iPad/macOS.
Rect? sharePositionOriginFor(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<void> _copyLinkFallback(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Enlace copiado al portapapeles'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

/// Comparte el perfil con el sheet nativo (WhatsApp, Instagram, etc.).
///
/// - Android / iOS app: Intent / UIActivityViewController.
/// - Mobile web: Web Share API (`navigator.share`) cuando el navegador lo soporta.
/// - Desktop web sin share API: copia al portapapeles.
Future<void> sharePublicBusinessProfile({
  required BuildContext context,
  required String slug,
  required String businessName,
  Rect? sharePositionOrigin,
}) async {
  final url = buildPublicBusinessProfileUrl(context, slug);
  final shareText = 'Reservá en $businessName: $url';

  Future<bool> tryShare(ShareParams params) async {
    try {
      await SharePlus.instance.share(params);
      return true;
    } catch (_) {
      return false;
    }
  }

  // 1) Link directo — mejor preview en iOS y Web Share API móvil.
  if (url.startsWith('http://') || url.startsWith('https://')) {
    final shared = await tryShare(
      ShareParams(
        uri: Uri.parse(url),
        title: businessName,
        subject: businessName,
        sharePositionOrigin: sharePositionOrigin,
        mailToFallbackEnabled: false,
      ),
    );
    if (shared) return;
  }

  // 2) Texto con URL — Android y fallback web.
  final sharedAsText = await tryShare(
    ShareParams(
      text: shareText,
      title: businessName,
      subject: businessName,
      sharePositionOrigin: sharePositionOrigin,
      mailToFallbackEnabled: false,
    ),
  );
  if (sharedAsText) return;

  if (!context.mounted) return;
  await _copyLinkFallback(context, url);
}
