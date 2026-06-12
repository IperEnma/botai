import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/agenda/me_profile_provider.dart';
import '../../../providers/agenda/selected_agenda_business_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import 'business_section_screen.dart';

/// Sección del panel sin UUID en la URL (`/agenda/panel/section/:section`).
class AgendaPanelSectionScreen extends ConsumerWidget {
  const AgendaPanelSectionScreen({super.key, required this.section});

  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // STAFF puro: solo puede ver la sección "Agenda". Cualquier otra sección
    // (Equipo, Servicios, Configuración, etc.) la redirige a su calendario.
    if (readMeProfileOrEmpty(ref).isStaffOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/agenda/panel?section=agenda');
      });
      return const Scaffold(body: AgendaLoadingView());
    }
    final businessId = ref.watch(selectedAgendaBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/agenda/panel');
      });
      return const Scaffold(body: AgendaLoadingView());
    }
    return BusinessSectionScreen(businessId: businessId, section: section);
  }
}
