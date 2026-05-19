import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../register/konecta_tokens.dart';
import '../models/member.dart';
import '../providers/equipo_provider.dart';
import '../widgets/add_member_panel.dart';
import '../widgets/equipo_page_header.dart';
import '../widgets/equipo_toolbar.dart';
import '../widgets/member_detail_panel.dart';
import '../widgets/members_table.dart';

class EquipoScreen extends ConsumerWidget {
  const EquipoScreen({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tenantId: tenantId, businessId: businessId);
    final state = ref.watch(equipoProvider(key));
    final notifier = ref.read(equipoProvider(key).notifier);

    if (state.isLoading) {
      return Container(
        color: KTokens.bg,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Container(
        color: KTokens.bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: KTokens.inkPlaceholder),
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: KTokens.inkMuted,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.refresh(equipoProvider(key)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: KTokens.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EquipoPageHeader(
              onAddMember: () => showAddMemberPanel(context, key),
              onImport: () {},
            ),
            const SizedBox(height: 22),
            EquipoToolbar(
              state: state,
              onSearch: notifier.setSearch,
              onFilter: notifier.setFilter,
            ),
            const SizedBox(height: 16),
            MembersTable(
              state: state,
              onMemberTap: (member) =>
                  _openDetail(context, member, notifier, key),
              onStatusChange: (id, status) => notifier.setStatus(id, status),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    Member member,
    EquipoNotifier notifier,
    EquipoKey key,
  ) {
    showMemberDetailPanel(context, member, notifier, key);
  }
}
