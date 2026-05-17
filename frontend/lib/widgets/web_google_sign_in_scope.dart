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
  bool _handling = false;

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
    if (!kIsWeb || !mounted || _handling) return;
    if (account == null) return;

    final auth = ref.read(authStateProvider);
    if (auth.isAuthenticated && auth.user?.email == account.email) {
      return;
    }

    _handling = true;
    try {
      final ok = await ref
          .read(authStateProvider.notifier)
          .completeGoogleSignInFromAccount(account);
      if (!mounted) return;
      final after = ref.read(authStateProvider);
      if (!ok || after.error != null) {
        if (after.error != null) {
          await showApiErrorDialog(
            context,
            Exception(after.error!),
            title: widget.errorDialogTitle,
          );
        }
        return;
      }
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
