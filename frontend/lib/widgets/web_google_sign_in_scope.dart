import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/api_error_presenter.dart';
import '../providers/auth_provider.dart';

/// Web only: GIS `renderButton` updates [GoogleSignIn.onCurrentUserChanged] with an account that includes `id_token`.
class WebGoogleSignInScope extends ConsumerStatefulWidget {
  const WebGoogleSignInScope({
    super.key,
    required this.child,
    required this.onSignedIn,
    this.errorDialogTitle = 'Inicio de sesión con Google',
  });

  final Widget child;
  final Future<void> Function(BuildContext context) onSignedIn;
  final String errorDialogTitle;

  @override
  ConsumerState<WebGoogleSignInScope> createState() =>
      _WebGoogleSignInScopeState();
}

class _WebGoogleSignInScopeState extends ConsumerState<WebGoogleSignInScope> {
  StreamSubscription<GoogleSignInAccount?>? _sub;

  // Static: shared across ALL instances so that two simultaneous WebGoogleSignInScope
  // widgets (e.g. LoginScreen + RegisterScreen) cannot both process the same GIS event.
  static bool _handling = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final google = ref.read(authServiceProvider).googleSignIn;
      _sub = google.onCurrentUserChanged.listen(_onGoogleUser);
    });
  }

  Future<void> _onGoogleUser(GoogleSignInAccount? account) async {
    debugPrint('[GIS] onCurrentUserChanged — account=${account?.email} mounted=$mounted handling=$_handling');
    if (!kIsWeb || !mounted || _handling) return;
    if (account == null) return;

    _handling = true;
    try {
      // If not yet authenticated as this account, complete the sign-in.
      // If already authenticated (e.g. session restored from storage on app
      // start), skip the auth update but still call onSignedIn so the user
      // is routed to the right screen (home vs onboarding).
      final auth = ref.read(authStateProvider);
      debugPrint('[GIS] auth.isAuthenticated=${auth.isAuthenticated} auth.email=${auth.user?.email}');
      if (!auth.isAuthenticated || auth.user?.email != account.email) {
        debugPrint('[GIS] completando completeGoogleSignInFromAccount');
        await ref
            .read(authStateProvider.notifier)
            .completeGoogleSignInFromAccount(account);
        if (!mounted) return;
        final after = ref.read(authStateProvider);
        if (after.error != null) {
          debugPrint('[GIS] error tras completeGoogleSignInFromAccount: ${after.error}');
          await showApiErrorDialog(
            context,
            Exception(after.error!),
            title: widget.errorDialogTitle,
          );
          return;
        }
        if (!after.isAuthenticated) return;
      } else {
        debugPrint('[GIS] sesión ya activa con este email — saltando completeGoogleSignInFromAccount');
      }
      debugPrint('[GIS] llamando onSignedIn');
      await widget.onSignedIn(context);
    } finally {
      _handling = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
