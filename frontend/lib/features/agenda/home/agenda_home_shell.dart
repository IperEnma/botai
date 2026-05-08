import 'package:flutter/material.dart';

/// Contenedor de rutas `/home/**`. La navegación lateral vive en el panel Agenda
/// ([`TenantHomeScreen`]); aquí solo pasamos el hijo para no duplicar barras.
class AgendaHomeShell extends StatelessWidget {
  const AgendaHomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
