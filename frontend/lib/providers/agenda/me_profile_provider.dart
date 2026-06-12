import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/agenda/me_profile.dart';
import '../../services/agenda_api_exception.dart';
import '../auth_provider.dart';
import 'agenda_api_provider.dart';

/// Perfil RBAC del usuario autenticado.
///
/// Se carga la primera vez que se lee (asíncronamente) llamando a
/// `GET /api/agenda/me/profile`. `autoDispose` para que se re-fetche al
/// re-montar la pantalla que lo usa (e.g. el panel tras registrar un negocio),
/// sin requerir un `invalidate` explícito en cada flujo de mutación.
final meProfileProvider = FutureProvider.autoDispose<AgendaMeProfile>((ref) async {
  // Re-fetchear cada vez que el access token cambia: una nueva sesión Google
  // implica un usuario potencialmente distinto.
  final authState = ref.watch(authStateProvider);
  if (authState.user?.accessToken == null) {
    return AgendaMeProfile.empty();
  }
  final api = ref.read(agendaApiServiceProvider);
  try {
    return await api.fetchMeProfile();
  } on AgendaApiException {
    // El usuario está autenticado pero el backend no resolvió perfil (legacy
    // sin tenant, o feature flag off). El frontend tratará como sin permisos.
    return AgendaMeProfile.empty();
  }
});

/// Helper sincrónico para gatear UI: devuelve el perfil ya cargado, o un
/// `AgendaMeProfile.empty()` mientras carga / si hay error. Esto permite usar
/// helpers como `profile.tenantAdmin` directamente en `build()` sin manejar
/// `AsyncValue` en cada llamada.
AgendaMeProfile readMeProfileOrEmpty(WidgetRef ref) =>
    ref.watch(meProfileProvider).valueOrNull ?? AgendaMeProfile.empty();
