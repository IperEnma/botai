import 'dart:convert';
import 'dart:html' as html;

/// Si el deploy en Vercel cambió, recarga la pestaña (sin pedir al usuario borrar caché).
Future<void> ensureLatestWebDeploy() async {
  const embedded = String.fromEnvironment('WEB_BUILD_ID', defaultValue: '');
  if (embedded.isEmpty) return;

  try {
    final uri = Uri.parse(
      '/version.json?t=${DateTime.now().millisecondsSinceEpoch}',
    );
    final resp = await html.HttpRequest.request(
      uri.toString(),
      method: 'GET',
      requestHeaders: const {'Cache-Control': 'no-cache'},
    );
    if (resp.status != 200 || resp.responseText == null) return;

    final json = jsonDecode(resp.responseText!) as Map<String, dynamic>;
    final remote = json['buildId']?.toString() ?? '';
    if (remote.isNotEmpty && remote != embedded) {
      html.window.location.reload();
    }
  } catch (_) {
    // Sin red o version.json ausente: seguir con la build embebida.
  }
}
