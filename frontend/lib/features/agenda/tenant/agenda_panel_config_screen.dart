import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/agenda/selected_agenda_business_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import 'business_me_config_screen.dart';

/// Config del negocio sin UUID en la URL (`/agenda/panel/config`).
class AgendaPanelConfigScreen extends ConsumerWidget {
  const AgendaPanelConfigScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessId = ref.watch(selectedAgendaBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/agenda/panel');
      });
      return const Scaffold(body: AgendaLoadingView());
    }
    return BusinessMeConfigScreen(
      businessId: businessId,
      initialTabIndex: initialTabIndex,
    );
  }
}
