import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/agenda/selected_agenda_business_provider.dart';

/// Cuando es true, las rutas del admin no llevan tenant ni UUID de sucursal en la URL.
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

/// Selecciona sucursal en estado (login ya resolvió el tenant) y navega al panel.
void navigateAgendaTenantBusiness(
  BuildContext context,
  WidgetRef ref,
  String businessId, {
  int? tab,
}) {
  ref.read(selectedAgendaBusinessIdProvider.notifier).state = businessId;
  if (tab != null && tab != 0) {
    context.go('/agenda/panel/config?tab=$tab');
  } else {
    context.go('/agenda/panel');
  }
}

/// @deprecated Usar [navigateAgendaTenantBusiness]. Mantenido para firmas con tenantId ignorado.
String agendaTenantBusinessPath(
  BuildContext context,
  String tenantId,
  String businessId, {
  int? tab,
}) {
  final tabQ = tab != null && tab != 0 ? '?tab=$tab' : '';
  return '/agenda/panel$tabQ';
}
