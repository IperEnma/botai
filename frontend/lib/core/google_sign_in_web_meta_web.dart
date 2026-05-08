import 'dart:html' as html;

/// GIS / FedCM en el navegador suelen exigir la meta `google-signin-client_id`
/// para devolver **id_token** (JWT). La inyectamos desde el mismo valor que `.env`.
void ensureGoogleSignInWebMeta(String clientId) {
  final id = clientId.trim();
  if (id.isEmpty) return;
  final head = html.document.head;
  if (head == null) return;

  final existing =
      html.document.querySelector('meta[name="google-signin-client_id"]');
  if (existing != null) {
    existing.setAttribute('content', id);
    return;
  }

  final meta = html.MetaElement()
    ..name = 'google-signin-client_id'
    ..content = id;
  head.append(meta);
}
