import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/agenda_api_exception.dart';

/// Interpreta cuerpos JSON de error (Agenda, OAuth2 / Spring Resource Server, etc.).
String parseHttpErrorBody(
  int statusCode,
  String body, {
  Map<String, String>? headers,
}) {
  final buf = StringBuffer('HTTP $statusCode');
  final www = headers?['www-authenticate'] ?? headers?['WWW-Authenticate'];
  if (www != null && www.isNotEmpty) {
    buf.write('\nWWW-Authenticate: $www');
  }
  if (body.isEmpty) {
    return buf.toString();
  }

  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final msg = decoded['message']?.toString();
      final code = decoded['code']?.toString();
      final err = decoded['error']?.toString();
      final desc = decoded['error_description']?.toString();

      if (msg != null && msg.isNotEmpty) {
        buf.write('\n$msg');
        if (code != null && code.isNotEmpty) buf.write(' ($code)');
        return buf.toString();
      }
      if (err != null && err.isNotEmpty) {
        buf.write('\n');
        buf.write(desc != null && desc.isNotEmpty ? '$err: $desc' : err);
        return buf.toString();
      }
    }
  } catch (_) {
    /* seguir con texto plano */
  }

  final trimmed = body.length > 1200 ? '${body.substring(0, 1200)}…' : body;
  buf.write('\n$trimmed');
  return buf.toString();
}

/// Texto único para mostrar en UI (p. ej. diálogo tras iniciar sesión).
String describeErrorForUser(Object error) {
  if (error is AgendaApiException) {
    return error.userVisibleFull;
  }
  if (error is Exception) {
    return error.toString();
  }
  return error.toString();
}

/// Muestra el error real en un diálogo con texto seleccionable (útil para copiar).
Future<void> showApiErrorDialog(
  BuildContext context,
  Object error, {
  String title = 'Error',
}) async {
  final text = describeErrorForUser(error);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
