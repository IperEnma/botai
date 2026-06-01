/// Cómo se agenda un servicio en reservas públicas.
enum ServiceSchedulingMode {
  general,
  byStaff;

  static ServiceSchedulingMode fromApi(String? value) {
    if (value == null) return ServiceSchedulingMode.general;
    switch (value.toUpperCase()) {
      case 'BY_STAFF':
        return ServiceSchedulingMode.byStaff;
      default:
        return ServiceSchedulingMode.general;
    }
  }

  String toApi() => this == ServiceSchedulingMode.byStaff ? 'BY_STAFF' : 'GENERAL';
}
