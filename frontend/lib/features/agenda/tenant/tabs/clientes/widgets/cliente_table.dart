import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../register/konecta_tokens.dart';
import '../cliente.dart';
import '../clientes_controller.dart';
import 'cliente_row.dart';

class ClienteTable extends ConsumerWidget {
  const ClienteTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(clientesProvider.notifier);
    final visible = notifier.visible;
    final selectedId = ref.watch(clientesProvider).selectedId;

    if (visible.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: KTokens.surface,
          border: Border.all(color: KTokens.border),
          borderRadius: BorderRadius.circular(KTokens.rMd),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline,
                size: 36, color: KTokens.inkPlaceholder),
            const SizedBox(height: 8),
            Text(
              'Sin clientes que coincidan',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: KTokens.inkMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF7),
        borderRadius: BorderRadius.circular(KTokens.rMd),
        border: Border.all(color: KTokens.border),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ClienteTableHeader(),
          for (final c in visible)
            ClienteRow(
              cliente: c,
              tag: notifier.tagOf(c),
              selected: c.id == selectedId,
              onTap: () => notifier.select(c.id),
            ),
        ],
      ),
    );
  }
}

/// Versión móvil (lista compacta de tarjetas).
class ClientesMobileList extends ConsumerWidget {
  const ClientesMobileList({super.key, required this.onOpen});

  final ValueChanged<Cliente> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(clientesProvider.notifier);
    final visible = notifier.visible;

    return Column(
      children: [
        for (final c in visible)
          ClienteRow(
            cliente: c,
            tag: notifier.tagOf(c),
            selected: false,
            onTap: () {
              notifier.select(c.id);
              onOpen(c);
            },
          ),
      ],
    );
  }
}
