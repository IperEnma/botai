import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../register/konecta_tokens.dart';
import '../cliente.dart';
import '../clientes_controller.dart';
import 'cliente_row.dart';
import 'tag_chip.dart';

class ClienteTable extends ConsumerWidget {
  const ClienteTable({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(clientesProvider(businessId).notifier);
    final visible = notifier.visible;
    final selectedId = ref.watch(clientesProvider(businessId)).selectedId;

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
  const ClientesMobileList({
    super.key,
    required this.businessId,
    required this.onOpen,
  });

  final String businessId;
  final ValueChanged<Cliente> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(clientesProvider(businessId).notifier);
    final visible = notifier.visible;

    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 36, color: KTokens.inkPlaceholder),
            const SizedBox(height: 8),
            Text(
              'Sin clientes que coincidan',
              style: GoogleFonts.inter(fontSize: 14, color: KTokens.inkMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final c in visible)
          _MobileCard(
            cliente: c,
            tag: notifier.tagOf(c),
            onTap: () {
              notifier.select(c.id);
              onOpen(c);
            },
          ),
      ],
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard({
    required this.cliente,
    required this.tag,
    required this.onTap,
  });

  final Cliente cliente;
  final ClienteTag tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final servicio = cliente.servicioTop?.servicio ?? '—';
    final gasto = '\$ ${_money(cliente.gastoAcumulado)}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: KTokens.surface,
          borderRadius: BorderRadius.circular(KTokens.rMd),
          border: Border.all(color: KTokens.border),
        ),
        child: Row(
          children: [
            ClienteAvatar(cliente: cliente, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cliente.nombre,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: KTokens.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TagChip(tag: tag),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    cliente.telefono,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      color: KTokens.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cliente.visitas} visitas · $servicio · $gasto',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: KTokens.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 18, color: KTokens.inkPlaceholder),
          ],
        ),
      ),
    );
  }
}

String _money(double v) {
  final whole = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final pos = whole.length - i;
    buf.write(whole[i]);
    if (pos > 1 && (pos - 1) % 3 == 0) buf.write('.');
  }
  return buf.toString();
}
