import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// URL pública del perfil `/reservar/:slug` (con query `company` si aplica).
String buildPublicBusinessProfileUrl(BuildContext context, String slug) {
  final uri = GoRouterState.of(context).uri;
  final path = uri.queryParameters.isEmpty
      ? '/reservar/$slug'
      : '/reservar/$slug?${uri.queryParameters.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';

  if (kIsWeb) {
    final origin = Uri.base.origin;
    if (origin.isNotEmpty && origin != 'null') {
      return '$origin$path';
    }
  }

  final configured = dotenv.env['PUBLIC_APP_BASE_URL']?.trim();
  if (configured != null && configured.isNotEmpty) {
    final base = configured.endsWith('/') ? configured.substring(0, configured.length - 1) : configured;
    return '$base$path';
  }

  return path;
}

bool get _useNativeShare {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    default:
      return false;
  }
}

/// Comparte el perfil: sheet nativo en móvil; copia al portapapeles en web/PC.
Future<void> sharePublicBusinessProfile({
  required BuildContext context,
  required String slug,
  required String businessName,
}) async {
  final url = buildPublicBusinessProfileUrl(context, slug);
  final text = 'Reservá en $businessName: $url';

  if (_useNativeShare) {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: businessName),
    );
    return;
  }

  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Enlace copiado al portapapeles'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
