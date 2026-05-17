import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_post_login.dart';

/// Tras Google Sign-In explícito (web GIS / botón). La navegación también la hace
/// [AuthSessionCoordinator] por si el `Future` de `signIn()` no completa en móvil.
Future<void> agendaNavigateAfterGoogleSignIn(
  WidgetRef ref,
  BuildContext context,
) async {
  navigateAfterAuthenticatedSession(ref);
}
