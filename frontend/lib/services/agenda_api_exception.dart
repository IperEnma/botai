/// Excepción tipada lanzada por [AgendaApiService] cuando el backend devuelve
/// un error (4xx/5xx) o cuando el cuerpo no se puede parsear.
///
/// Mapea el formato `{ "code": "...", "message": "..." }` que devuelve
/// `AgendaGlobalExceptionHandler` del backend.
class AgendaApiException implements Exception {
  /// Código de error del backend (ej. `BUSINESS_NOT_FOUND`, `SLOT_TAKEN`).
  /// `null` cuando el error es de transporte o no trae body parseable.
  final String? code;

  /// Mensaje legible para mostrar en UI.
  final String message;

  /// Status HTTP. `0` cuando es error de transporte.
  final int status;

  /// Detalle extra (cuerpo recortado, cabeceras OAuth, etc.) para depuración en pantalla.
  final String? detail;

  const AgendaApiException({
    required this.message,
    required this.status,
    this.code,
    this.detail,
  });

  /// Mensaje + detalle para diálogos / SnackBars largos.
  String get userVisibleFull {
    if (detail == null || detail!.trim().isEmpty) return message;
    return '$message\n\n$detail';
  }

  /// Atajo: `true` si el endpoint protegido devolvió 404 por
  /// `AGENDA_ENABLED=false` en el tenant. La UI puede mostrar
  /// la pantalla "Agenda no disponible".
  bool get isFeatureDisabled => status == 404 && code == null;

  bool get isNotFound => status == 404;
  bool get isConflict => status == 409;
  bool get isUnprocessable => status == 422;

  @override
  String toString() =>
      'AgendaApiException(status=$status, code=$code, message=$message, detail=$detail)';
}
