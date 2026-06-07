import '../models/agenda/business.dart';

/// Texto de dirección usable en perfil público (campo dedicado o onboarding legacy).
String? resolveBusinessAddress(Business business) {
  final direct = business.direccion?.trim();
  if (direct != null && direct.isNotEmpty && AgendaAddressFormat.validate(direct) == null) {
    return direct;
  }

  final fromDesc = _addressFromDescription(business.descripcion);
  if (fromDesc != null) return fromDesc;

  return null;
}

String? _addressFromDescription(String? descripcion) {
  if (descripcion == null || descripcion.isEmpty) return null;
  for (final line in descripcion.split('\n')) {
    final t = line.trim();
    if (t.startsWith('📍')) {
      final addr = t.substring(1).trim();
      if (addr.isNotEmpty && AgendaAddressFormat.validate(addr) == null) return addr;
    }
  }
  return null;
}

/// Validación de formato alineada con el backend (`BusinessAddressSupport`).
abstract final class AgendaAddressFormat {
  static String? validate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = raw.trim();
    if (v.length < 3) return 'La dirección es demasiado corta.';
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(v) || v.contains('/uploads/')) {
      return 'La dirección no puede ser una URL ni un enlace de archivo.';
    }
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(v)) {
      return 'La dirección debe incluir al menos una letra (ej. calle, barrio o ciudad).';
    }
    return null;
  }

  static bool looksLikeAreaOnly(String address) =>
      !RegExp(r'\d').hasMatch(address.trim());

  static String mapHintForPrecision(String precision, String address) {
    switch (precision) {
      case 'EXACT':
        return 'Ubicación exacta en el mapa.';
      case 'AREA':
        return 'Ubicación aproximada (barrio o ciudad).';
      case 'APPROXIMATE':
        return looksLikeAreaOnly(address)
            ? 'Ubicación aproximada en el mapa.'
            : 'Calle encontrada; el pin puede variar unos metros.';
      default:
        return '';
    }
  }
}

class AddressGeocodeResult {
  const AddressGeocodeResult({
    required this.found,
    this.lat,
    this.lon,
    this.displayName,
    required this.precision,
  });

  final bool found;
  final double? lat;
  final double? lon;
  final String? displayName;
  final String precision;

  factory AddressGeocodeResult.fromJson(Map<String, dynamic> json) {
    return AddressGeocodeResult(
      found: json['found'] == true,
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      displayName: json['displayName'] as String?,
      precision: (json['precision'] as String?) ?? 'NONE',
    );
  }

  static const notFound = AddressGeocodeResult(found: false, precision: 'NONE');
}
