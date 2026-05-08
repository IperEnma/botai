import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../services/agenda_api_service.dart';
import '../auth_provider.dart';

/// Singleton del cliente HTTP del módulo AGENDA.
///
/// Se mantiene aislado del `apiServiceProvider` del bot (no comparte instancia,
/// pero **sí** reusa el access token leyendo `authStateProvider`).
final agendaApiServiceProvider = Provider<AgendaApiService>((ref) {
  final api = AgendaApiService();

  // 1) User id por defecto desde .env (dev only) — el flow de auth real lo pisará
  api.setUserId(AppConfig.agendaDefaultUserId);

  // 2) Sincronizar access token con el authStateProvider del bot
  ref.listen(
    authStateProvider,
    (prev, next) {
      api.setAccessToken(next.user?.accessToken);
    },
    fireImmediately: true,
  );

  // 3) Si el backend devuelve 401 (token vencido), intentar renovar con Google sin UI y reintentar.
  api.setRefreshAccessTokenCallback(() async {
    final ok = await ref.read(authStateProvider.notifier).refreshSessionSilently();
    if (!ok) return null;
    return ref.read(authStateProvider).user?.accessToken;
  });

  ref.onDispose(api.close);
  return api;
});
