import 'package:flutter/material.dart';

/// Shell del panel Agenda. Mantiene la navegación lateral propia de cada
/// pantalla y aplica una **transición uniforme** cuando se cambia entre
/// secciones (Inicio, Horarios, Servicios, Configuración, etc.).
///
/// La transición se controla aquí — y no en `go_router` — para garantizar
/// el mismo movimiento elegante en todas las secciones, sin depender del
/// tipo de ruta ni de si la pantalla destino redefine su propio `Scaffold`.
///
/// Patrón: *fade-through* tipo Material — la sección saliente se desvanece
/// y se hunde ligeramente; la nueva entra con un pequeño levantamiento
/// (8 px) y una escala sutil (0.98 → 1.0). Da sensación de profundidad
/// sin retardar la app.
class AgendaHomeShell extends StatelessWidget {
  const AgendaHomeShell({
    super.key,
    required this.child,
    required this.locationKey,
  });

  final Widget child;

  /// URI completa de la ruta actual. Cambia cada vez que el usuario navega
  /// a otra sección; el `AnimatedSwitcher` lo usa como `key`.
  final String locationKey;

  static const _kDuration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _kDuration,
      reverseDuration: _kDuration,
      // Stagger: la entrante aparece en el último 55% del ciclo,
      // la saliente se va en el primer 50%. Evita el "barro visual" del
      // cross-fade puro y le da un ritmo claro: sale → entra.
      switchInCurve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
      switchOutCurve: const Interval(0.0, 0.5, curve: Curves.easeInCubic),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.0, 0.012), // ~8 px hacia abajo
          end: Offset.zero,
        ).animate(animation);
        final scale = Tween<double>(
          begin: 0.985,
          end: 1.0,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topLeft,
          fit: StackFit.expand,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(locationKey),
        child: child,
      ),
    );
  }
}
