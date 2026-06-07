/// Google Maps sin API key: enlaces oficiales + iframe embed en web.
abstract final class GoogleMapsUrls {
  /// Barra "Maps ↗" del iframe embed gratuito de Google (se recorta visualmente).
  static const embedTopChromeCrop = 46.0;

  /// Abre la dirección en Google Maps (web o app nativa).
  static String search(String address) {
    final q = Uri.encodeComponent(address.trim());
    return 'https://www.google.com/maps/search/?api=1&query=$q';
  }

  /// Abre coordenadas en Google Maps.
  static String searchCoords({required double lat, required double lng}) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }

  /// Iframe embed gratuito (sin API key). Preferir coordenadas si están disponibles.
  static String embed({
    String? address,
    double? lat,
    double? lng,
    int zoom = 15,
  }) {
    final query = (lat != null && lng != null)
        ? '$lat,$lng'
        : Uri.encodeComponent((address ?? '').trim());
    return 'https://maps.google.com/maps?q=$query&hl=es&z=$zoom&output=embed';
  }
}
