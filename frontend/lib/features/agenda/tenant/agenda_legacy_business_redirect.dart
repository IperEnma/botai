import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/agenda/selected_agenda_business_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

/// Bookmarks viejos con UUID en la URL: guarda la sucursal en estado y va a `/agenda/panel`.
class AgendaLegacyBusinessRedirect extends ConsumerStatefulWidget {
  const AgendaLegacyBusinessRedirect({
    super.key,
    required this.businessId,
    required this.targetPath,
  });

  final String businessId;
  final String targetPath;

  @override
  ConsumerState<AgendaLegacyBusinessRedirect> createState() =>
      _AgendaLegacyBusinessRedirectState();
}

class _AgendaLegacyBusinessRedirectState
    extends ConsumerState<AgendaLegacyBusinessRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectedAgendaBusinessIdProvider.notifier).state =
          widget.businessId;
      context.go(widget.targetPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFBFAF7),
      body: AgendaLoadingView(),
    );
  }
}
