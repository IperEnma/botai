import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import '../../../providers/agenda/tenant_admin_resolved_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../providers/bot_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../../agenda/tenant/widgets/agenda_left_nav.dart';
import '../empty/bots_empty_view.dart';
import '../panels/create_bot_panel.dart';
import 'bots_list_view.dart';

class BotsScreen extends ConsumerWidget {
  const BotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(body: AgendaLoadingView());
    }

    final async = ref.watch(tenantAdminResolvedProvider);

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFFBFAF7),
        body: AgendaLoadingView(),
      ),
      error: (e, _) {
        if (e is TenantAdminResolveException &&
            e.code == 'NOT_AUTHENTICATED') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const Scaffold(body: AgendaLoadingView());
        }
        return Scaffold(
          backgroundColor: const Color(0xFFFBFAF7),
          body: AgendaErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(tenantAdminResolvedProvider),
          ),
        );
      },
      data: (ctx) => _BotsView(tenantId: ctx.tenantId),
    );
  }
}

// ─── View ─────────────────────────────────────────────────────────────────────

const _kBreak = 1024.0;

class _BotsView extends ConsumerStatefulWidget {
  const _BotsView({required this.tenantId});
  final String tenantId;

  @override
  ConsumerState<_BotsView> createState() => _BotsViewState();
}

class _BotsViewState extends ConsumerState<_BotsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(botsProvider.notifier).loadBots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _kBreak;

    final nombre = ref.watch(agendaUserProvider).valueOrNull?.nombre;
    final bizState = ref.watch(businessesProvider(widget.tenantId));
    final firstBiz = bizState.items.firstOrNull;
    final businessId = firstBiz?.id;
    final businessName = firstBiz?.nombre;

    final botsState = ref.watch(botsProvider);
    final hasActiveBots = botsState.bots.isNotEmpty;

    Widget content;

    Future<void> openCreatePanel() async {
      await showCreateBotPanel(context, tenantId: widget.tenantId);
      if (mounted) ref.read(botsProvider.notifier).loadBots();
    }

    if (hasActiveBots) {
      content = Scaffold(
        backgroundColor: const Color(0xFFFBFAF7),
        body: BotsListView(
          onCreate: openCreatePanel,
          onBotTap: (bot) => context.go('/bots/${bot.id}'),
        ),
      );
    } else {
      content = Scaffold(
        backgroundColor: const Color(0xFFFBFAF7),
        body: BotsEmptyView(
          onCreate: openCreatePanel,
        ),
      );
    }

    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBFAF7),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AgendaLeftNav(
              nombre: nombre,
              businessName: businessName,
              tenantId: widget.tenantId,
              businessId: businessId,
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return content;
  }
}
