import 'package:flutter/material.dart';

import '../register/konecta_tokens.dart';

/// Top bar unificada para mobile del panel admin Konecta.
///
/// Botón hamburguesa (abre el `Drawer` del Scaffold ancestro) + marca "konecta".
/// Reemplaza al AppBar morado en las secciones — todas las pantallas mobile
/// usan exactamente este componente para mantener consistencia con Inicio.
///
/// Requiere que exista un `Scaffold` ancestro con `drawer:` configurado.
class KMobileTopBar extends StatelessWidget {
  const KMobileTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: KTokens.surface,
        border: Border(bottom: BorderSide(color: KTokens.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: KTokens.borderStrong),
              ),
              child: const Icon(
                Icons.menu_rounded,
                size: 16,
                color: KTokens.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'konecta',
            style: KTokens.tBrand.copyWith(color: KTokens.accent),
          ),
        ],
      ),
    );
  }
}
