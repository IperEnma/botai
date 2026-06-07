import '../core/config.dart';

/// Preview estático OSM vía backend (sin CORS). Al tocar, la app abre Google Maps.
abstract final class OpenStreetMapPreview {
  static String geocodeQuery({
    required String address,
    Iterable<String> locationHints = const [],
  }) {
    final parts = <String>[
      address.trim(),
      ...locationHints.map((h) => h.trim()).where((h) => h.isNotEmpty),
      'Uruguay',
    ];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  static String previewImageUrl(String geocodeQuery, {int pixelSize = 192}) {
    final q = Uri.encodeComponent(geocodeQuery.trim());
    final size = pixelSize.clamp(64, 512);
    return '${AppConfig.agendaApiBaseUrl}/public/map-preview?address=$q&size=$size';
  }
}
