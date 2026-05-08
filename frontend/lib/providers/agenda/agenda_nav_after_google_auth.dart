import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/agenda_api_exception.dart';
import '../auth_provider.dart';
import 'agenda_api_provider.dart';
import 'agenda_user_provider.dart';

/// Tras Google Sign-In: si ya existe tenant Agenda para el correo → `/home`;
/// si no (404) → guarda datos para registro por email y va a `/agenda/intent`
/// (mismo onboarding que WhatsApp).
///
/// Fuerza token y email en [AgendaApiService] para evitar carreras con el
/// listener de Riverpod.
Future<void> agendaNavigateAfterGoogleSignIn(
  WidgetRef ref,
  BuildContext context,
) async {
  final auth = ref.read(authStateProvider);
  final user = auth.user;
  if (user == null || user.email.isEmpty) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  final api = ref.read(agendaApiServiceProvider);
  api.setAccessToken(user.accessToken);

  try {
    await api.fetchTenantAdminContext();
    if (!context.mounted) return;
    context.go('/home');
  } on AgendaApiException catch (e) {
    if (!context.mounted) return;
    if (!e.isNotFound) {
      messenger?.showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: const Color(0xFFB91C1C),
      ));
      return;
    }
    final trimmedName = user.name?.trim();
    final nombre = (trimmedName != null && trimmedName.isNotEmpty)
        ? trimmedName
        : user.email.split('@').first;
    await ref.read(agendaUserProvider.notifier).saveGoogleRegistration(
          nombre: nombre,
          email: user.email,
        );
    if (!context.mounted) return;
    context.go('/agenda/intent');
  }
}
