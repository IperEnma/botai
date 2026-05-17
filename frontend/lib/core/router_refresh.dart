import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

/// Notifica a [GoRouter.refreshListenable] cuando cambia la sesión, sin recrear el router.
final routerRefreshListenableProvider = Provider<RouterRefreshListenable>((ref) {
  final listenable = RouterRefreshListenable();
  ref.onDispose(listenable.dispose);
  ref.listen(authStateProvider, (_, _) => listenable.refresh());
  return listenable;
});

class RouterRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}
