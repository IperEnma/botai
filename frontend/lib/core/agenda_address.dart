import '../models/agenda/business.dart';

/// Texto de dirección usable en perfil público (campo dedicado o onboarding legacy).
String? resolveBusinessAddress(Business business) {
  final direct = business.direccion?.trim();
  if (direct != null && direct.isNotEmpty && !_isInvalidAddress(direct)) {
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
      if (addr.isNotEmpty && !_isInvalidAddress(addr)) return addr;
    }
  }
  return null;
}

bool _isInvalidAddress(String value) {
  if (RegExp(r'^https?://', caseSensitive: false).hasMatch(value)) return true;
  if (value.contains('/uploads/')) return true;
  return false;
}
