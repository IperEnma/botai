import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../providers/auth_provider.dart';
import 'auth_post_login.dart';

/// Enlaza Google Sign-In (móvil) y cambios de [authStateProvider] con la navegación a `/home`.
///
/// En Android/iOS, al volver del selector de Google el `Future` de `signIn()` a veces no
/// termina; [GoogleSignIn.onCurrentUserChanged] sí dispara y aquí completamos la sesión.
class AuthSessionCoordinator extends ConsumerStatefulWidget {
  const AuthSessionCoordinator({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuthSessionCoordinator> createState() =>
      _AuthSessionCoordinatorState();
}

class _AuthSessionCoordinatorState extends ConsumerState<AuthSessionCoordinator> {
  StreamSubscription<GoogleSignInAccount?>? _googleSub;
  bool _handlingGoogle = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bindGoogleStream());
    }
  }

  void _bindGoogleStream() {
    if (!mounted || _googleSub != null) return;
    final google = ref.read(authServiceProvider).googleSignIn;
    _googleSub = google.onCurrentUserChanged.listen(_onGoogleAccount);
  }

  Future<void> _onGoogleAccount(GoogleSignInAccount? account) async {
    if (!mounted || account == null || _handlingGoogle) return;

    final auth = ref.read(authStateProvider);
    if (auth.isAuthenticated && auth.user?.email == account.email) {
      navigateAfterAuthenticatedSession(ref);
      return;
    }

    _handlingGoogle = true;
    try {
      final ok = await ref
          .read(authStateProvider.notifier)
          .completeGoogleSignInFromAccount(account);
      if (ok && mounted) {
        navigateAfterAuthenticatedSession(ref);
      }
    } finally {
      _handlingGoogle = false;
    }
  }

  @override
  void dispose() {
    _googleSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.isAuthenticated && prev?.isAuthenticated != true) {
        navigateAfterAuthenticatedSession(ref);
      }
    });
    return widget.child;
  }
}
