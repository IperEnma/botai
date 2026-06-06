import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi;

/// Official GIS button — returns a credential with `id_token` (JWT). `signIn()` on web does not.
/// [width] sets minimumWidth; clamp to GIS range [200, 600].
Widget buildGoogleIdentitySignInButton({double? width}) {
  final minWidth = (width ?? 360).clamp(200.0, 600.0);
  return gsi.renderButton(
    configuration: gsi.GSIButtonConfiguration(
      theme: gsi.GSIButtonTheme.outline,
      size: gsi.GSIButtonSize.large,
      text: gsi.GSIButtonText.continueWith,
      minimumWidth: minWidth,
      locale: 'es',
    ),
  );
}
