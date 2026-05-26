import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/bot.dart';
import '../../../providers/bot_provider.dart';
import '../../agenda/register/konecta_tokens.dart';
import '../widgets/add_bot_card.dart';
import '../widgets/bot_card.dart';
import '../widgets/channels_roadmap.dart';
import '../widgets/plan_bar.dart';

class BotsListView extends ConsumerWidget {
  const BotsListView({
    super.key,
    required this.onCreate,
    required this.onBotTap,
  });

  final VoidCallback onCreate;
  final ValueChanged<Bot> onBotTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(botsProvider);
    final notifier = ref.read(botsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageHeader(onCreate: onCreate),
          const SizedBox(height: 22),
          const PlanBar(),
          const SizedBox(height: 28),
          _BotsGrid(
            bots: state.bots,
            notifier: notifier,
            onBotTap: onBotTap,
            onCreate: onCreate,
          ),
          const SizedBox(height: 22),
          const ChannelsRoadmap(),
        ],
      ),
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────────────────

class _BotsGrid extends StatelessWidget {
  const _BotsGrid({
    required this.bots,
    required this.notifier,
    required this.onBotTap,
    required this.onCreate,
  });

  final List<Bot> bots;
  final BotsNotifier notifier;
  final ValueChanged<Bot> onBotTap;
  final VoidCallback onCreate;

  Widget _card(Bot? bot) {
    if (bot == null) return AddBotCard(onTap: onCreate);
    return BotCard(
      bot: bot,
      onTap: () => onBotTap(bot),
      onArchive: () => notifier.deleteBot(bot.id),
      onDuplicate: () => notifier.createBot(bot.copyWith(
        id: '',
        name: '${bot.name} (copia)',
        createdAt: DateTime.now(),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 720;
        final cols = wide ? 2 : 1;
        const gap = 16.0;

        final allItems = <Bot?>[...bots, null]; // null = AddBotCard

        final rows = <Widget>[];
        for (int i = 0; i < allItems.length; i += cols) {
          if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));

          if (cols == 1) {
            rows.add(_card(allItems[i]));
          } else {
            final hasRight = i + 1 < allItems.length;
            rows.add(Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _card(allItems[i])),
                const SizedBox(width: gap),
                Expanded(
                  child:
                      hasRight ? _card(allItems[i + 1]) : const SizedBox(),
                ),
              ],
            ));
          }
        }

        return Column(children: rows);
      },
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AUTOMATIZACIÓN',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: KTokens.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mis bots',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontStyle: FontStyle.italic,
                  color: KTokens.ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Asistentes que responden a tus clientes en WhatsApp. Cada uno tiene un propósito distinto — saludar, agendar, dar soporte.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: KTokens.inkMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        ElevatedButton(
          onPressed: onCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: KTokens.ink,
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KTokens.rSm),
            ),
            textStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          child: const Text('+ Crear bot'),
        ),
      ],
    );
  }
}
