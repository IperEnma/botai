import 'package:flutter/material.dart';

/// Cuando es true, las rutas usan `/home/...` (sin UUID ni `/agenda/tenants/me`).
class TenantNavScope extends InheritedWidget {
  const TenantNavScope({
    super.key,
    required this.useMeRoutes,
    required super.child,
  });

  final bool useMeRoutes;

  static bool useMeRoutesOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TenantNavScope>()?.useMeRoutes ?? false;
  }

  @override
  bool updateShouldNotify(TenantNavScope oldWidget) =>
      oldWidget.useMeRoutes != useMeRoutes;
}

/// Ruta al detalle de negocio (tabs Horarios, etc.).
String agendaTenantBusinessPath(
  BuildContext context,
  String tenantId,
  String businessId, {
  int? tab,
}) {
  final tabQ =
      tab != null && tab != 0 ? '?tab=$tab' : '';
  return '/home/businesses/$businessId$tabQ';
}
