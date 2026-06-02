import 'package:flutter/widgets.dart';

/// Validación y normalización de teléfono Agenda (alineado con [AgendaPhoneNormalizer] en backend).
bool isValidAgendaPhone(String? raw, {String defaultCountryCode = '598'}) {
  return normalizeAgendaPhoneDigits(raw, defaultCountryCode: defaultCountryCode).length >= 10;
}

/// Código de país por defecto según locale del dispositivo (solo dígitos).
String defaultAgendaCountryCodeDigits() {
  final iso =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode?.toUpperCase() ?? '';
  return switch (iso) {
    'UY' => '598',
    'AR' => '54',
    'BR' => '55',
    'CL' => '56',
    'PY' => '595',
    'BO' => '591',
    'CO' => '57',
    'MX' => '52',
    'ES' => '34',
    'US' => '1',
    _ => '598',
  };
}

/// Solo dígitos con código de país (E.164 sin +).
String normalizeAgendaPhoneDigits(
  String? raw, {
  String? defaultCountryCode,
}) {
  final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final cc = (defaultCountryCode ?? defaultAgendaCountryCodeDigits())
      .replaceAll(RegExp(r'\D'), '');
  if (cc.isEmpty) return digits;

  if (digits.startsWith(cc) && digits.length >= cc.length + 7) {
    return digits;
  }
  if (_looksInternational(digits, cc)) {
    return digits;
  }
  if (digits.startsWith('0') && digits.length >= 8) {
    return '$cc${digits.substring(1)}';
  }
  if (digits.length <= 10) {
    return '$cc$digits';
  }
  return digits;
}

bool _looksInternational(String digits, String homeCc) {
  if (digits.length < 11) return false;
  if (digits.startsWith(homeCc)) return true;
  return !digits.startsWith('0');
}
