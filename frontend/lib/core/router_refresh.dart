import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

/// Notifica a [GoRouter.refreshListenable] cuando cambia la sesión, sin recrear el router.
final routerRefreshListenableProvider = Provider<RouterRefreshListenable>((ref) {
  final listenable = RouterRefreshListenable();
  ref.onDispose(listenable.dispose);
  ref.listen(authStateProvider, (prev, next) {
    final wasIn = prev?.isAuthenticated ?? false;
    final isIn = next.isAuthenticated;
    final tokenChanged =
        prev?.user?.accessToken != next.user?.accessToken;
    if (wasIn != isIn || tokenChanged) {
      listenable.refresh();
    }
  });
  return listenable;
});

class RouterRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}
