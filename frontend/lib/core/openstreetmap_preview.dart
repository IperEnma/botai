import 'dart:convert';

import 'package:http/http.dart' as http;

/// Preview estático OSM (solo miniatura). Al tocar, la app abre Google Maps.
abstract final class OpenStreetMapPreview {
  static const _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const _staticMapBase = 'https://staticmap.openstreetmap.de/staticmap';
  static const _userAgent = 'BotaiAgenda/1.0 (public business profile)';

  static final Map<String, ({double lat, double lon})?> _geocodeCache = {};

  static Future<({double lat, double lon})?> geocode(String address) async {
    final key = address.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (_geocodeCache.containsKey(key)) return _geocodeCache[key];

    try {
      final uri = Uri.parse('$_nominatimBase/search').replace(
        queryParameters: {
          'q': address.trim(),
          'format': 'json',
          'limit': '1',
        },
      );
      final r = await http.get(
        uri,
        headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
      );
      if (r.statusCode != 200) {
        _geocodeCache[key] = null;
        return null;
      }
      final list = jsonDecode(r.body) as List<dynamic>;
      if (list.isEmpty) {
        _geocodeCache[key] = null;
        return null;
      }
      final item = list.first as Map<String, dynamic>;
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      if (lat == null || lon == null) {
        _geocodeCache[key] = null;
        return null;
      }
      final coords = (lat: lat, lon: lon);
      _geocodeCache[key] = coords;
      return coords;
    } catch (_) {
      _geocodeCache[key] = null;
      return null;
    }
  }

  /// Imagen estática sin API key (servicio comunitario OSM).
  static String staticMapUrl({
    required double lat,
    required double lon,
    int pixelSize = 192,
  }) {
    final size = pixelSize.clamp(64, 512);
    final center = '$lat,$lon';
    return '$_staticMapBase?center=$center&zoom=15&size=${size}x$size&markers=$center,purple';
  }
}
