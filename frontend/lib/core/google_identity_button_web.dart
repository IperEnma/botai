import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi;

/// Official GIS button — returns a credential with `id_token` (JWT). `signIn()` on web does not.
Widget buildGoogleIdentitySignInButton() {
  return gsi.renderButton(
    configuration: gsi.GSIButtonConfiguration(
      theme: gsi.GSIButtonTheme.outline,
      size: gsi.GSIButtonSize.large,
      text: gsi.GSIButtonText.continueWith,
      minimumWidth: 360,
      locale: 'es',
    ),
  );
}
