import 'package:flutter/foundation.dart';

import '../services/agenda_api_exception.dart';

/// Fase del flujo de subida (solo para logs de consola, no mostrar al usuario).
enum AgendaImageUploadStage {
  selection('selección'),
  prepare('preparación'),
  upload('subida');

  const AgendaImageUploadStage(this.label);
  final String label;
}

/// Metadatos del archivo original (solo para logs de consola).
class AgendaImageUploadContext {
  const AgendaImageUploadContext({
    this.fileName,
    this.fileSizeBytes,
    this.mimeType,
    this.purpose,
  });

  final String? fileName;
  final int? fileSizeBytes;
  final String? mimeType;

  /// Ej. logo, banner, work-photo.
  final String? purpose;

  Map<String, Object?> toLogMap() => {
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'fileSizeMb': fileSizeBytes == null
            ? null
            : (fileSizeBytes! / (1024 * 1024)).toStringAsFixed(2),
        'mimeType': mimeType,
        'purpose': purpose,
      };
}

const agendaImageTooLargeUserMessage =
    'La imagen es muy pesada. Elegí una más chica o guardala como JPG desde Fotos.';

const _genericUploadFailureMessage =
    'No pudimos subir la imagen. Probá con otra foto o intentá más tarde.';

/// Mensaje corto y no técnico para SnackBar / diálogo.
/// El detalle (HTTP, códigos, stack) va solo a [logAgendaImageUploadFailure].
String formatAgendaImageUploadError(
  Object error, {
  required AgendaImageUploadStage stage,
  AgendaImageUploadContext? file,
}) {
  if (error is AgendaApiException) {
    return _userMessageForApiError(error);
  }

  final msg = error.toString();
  if (msg.contains('Máx. 5 MB')) {
    return agendaImageTooLargeUserMessage;
  }
  if (msg.contains('no se pudo decodificar') ||
      msg.contains('naturalWidth') ||
      msg.contains('HEIC') ||
      msg.contains('HEIF')) {
    return 'Esta foto no se pudo usar. Probá guardarla como JPG o elegí otra imagen.';
  }
  if (msg.contains('tardó demasiado')) {
    return 'La imagen tardó demasiado. Probá con otra foto o mejor señal.';
  }
  if (msg.contains('No se pudo leer')) {
    return 'No pudimos abrir esa imagen. Elegila de nuevo.';
  }
  if (msg.contains('máximo de') && msg.contains('fotos')) {
    return 'Ya llegaste al límite de fotos de tu negocio.';
  }

  return _genericUploadFailureMessage;
}

String _userMessageForApiError(AgendaApiException e) {
  if (e.status == 0) {
    return 'Revisá tu conexión e intentá de nuevo.';
  }
  if (e.status == 401 || e.status == 403) {
    return 'No tenés permiso para subir esta imagen.';
  }
  if (e.status == 404) {
    return 'No encontramos el negocio. Recargá la página e intentá de nuevo.';
  }
  if (e.status == 413) {
    return agendaImageTooLargeUserMessage;
  }
  if (e.status == 409) {
    return 'No se pudo guardar la imagen porque hubo un conflicto. Intentá de nuevo.';
  }
  if (e.status == 422) {
    return _sanitizeBackendMessage(e.message) ?? _genericUploadFailureMessage;
  }
  final sanitized = _sanitizeBackendMessage(e.message);
  if (sanitized != null) {
    return sanitized;
  }
  return _genericUploadFailureMessage;
}

/// Devuelve el mensaje solo si parece legible para el usuario final.
String? _sanitizeBackendMessage(String? message) {
  if (message == null || message.trim().isEmpty) return null;
  final m = message.trim();
  if (RegExp(r'^\d{3}$').hasMatch(m)) return null;
  if (m.startsWith('Error ')) return null;
  if (m.contains('HTTP')) return null;
  if (m.contains('Exception')) return null;
  if (m.contains('java.') || m.contains('org.')) return null;
  if (m.length > 160) return null;
  return m;
}

/// Registra en consola (Safari Web Inspector en iPhone) el detalle completo.
void logAgendaImageUploadFailure(
  Object error,
  StackTrace stackTrace, {
  required AgendaImageUploadStage stage,
  AgendaImageUploadContext? file,
}) {
  final buffer = StringBuffer('[agenda-upload] stage=${stage.name}');
  if (file != null) {
    for (final e in file.toLogMap().entries) {
      if (e.value != null) buffer.write(' ${e.key}=${e.value}');
    }
  }
  if (error is AgendaApiException) {
    buffer.write(
      ' status=${error.status} code=${error.code} message=${error.message}',
    );
    if (error.detail != null && error.detail!.isNotEmpty) {
      buffer.write(' detail=${error.detail}');
    }
  } else {
    buffer.write(' error=$error');
  }
  debugPrint(buffer.toString());
  if (kDebugMode) {
    debugPrintStack(stackTrace: stackTrace, label: '[agenda-upload] stack');
  }
}

AgendaImageUploadContext agendaUploadContextFromWebFile({
  required String name,
  required int size,
  String? mimeType,
  String? purpose,
}) {
  return AgendaImageUploadContext(
    fileName: name,
    fileSizeBytes: size,
    mimeType: mimeType,
    purpose: purpose,
  );
}
