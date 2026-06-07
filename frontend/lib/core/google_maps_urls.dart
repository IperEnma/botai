import 'package:flutter_dotenv/flutter_dotenv.dart';

/// URLs de Google Maps para la sección Ubicación del perfil público.
abstract final class GoogleMapsUrls {
  static String? get _apiKey {
    final v = dotenv.env['GOOGLE_MAPS_API_KEY'];
    return (v == null || v.trim().isEmpty) ? null : v.trim();
  }

  /// Abre la dirección en Google Maps (navegador / app).
  static String search(String address) {
    final q = Uri.encodeComponent(address.trim());
    return 'https://www.google.com/maps/search/?api=1&query=$q';
  }

  /// Miniatura estática (requiere `GOOGLE_MAPS_API_KEY` en `.env`).
  static String? staticMapThumbnail(String address, {int size = 192}) {
    final key = _apiKey;
    if (key == null) return null;
    final q = Uri.encodeComponent(address.trim());
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$q'
        '&zoom=15'
        '&size=${size}x$size'
        '&scale=2'
        '&maptype=roadmap'
        '&markers=size:mid%7Ccolor:0x7C5CFF%7C$q'
        '&key=$key';
  }
}
