import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../models/bot.dart';
import '../models/bot.dart';
import 'capa_badge.dart';
import 'channel_chip.dart';

class BotCard extends StatefulWidget {
  const BotCard({
    super.key,
    required this.bot,
    required this.onTap,
    required this.onArchive,
    required this.onDuplicate,
  });

  final Bot bot;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDuplicate;

  @override
  State<BotCard> createState() => _BotCardState();
}

class _BotCardState extends State<BotCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bot = widget.bot;
    final capa = capaFromTier(bot.tier);
    final color = colorForCapa(capa);
    final icon = iconForBot(bot.name);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: KTokens.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovering ? KTokens.borderStrong : KTokens.border,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + name + menu
              Row(
                children: [
                  _Avatar(color: color, icon: icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bot.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: KTokens.ink,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          bot.tierLabel,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: KTokens.inkSoft,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BotMenu(
                    onEdit: widget.onTap,
                    onDuplicate: widget.onDuplicate,
                    onDelete: widget.onArchive,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Description
              Text(
                bot.description ?? '',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: KTokens.inkMuted,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              // Footer
              const Divider(height: 1, color: KTokens.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  CapaBadge(capa: capa),
                  const SizedBox(width: 6),
                  ChannelChip(
                    channel: BotChannel.whatsapp,
                    active: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.color, required this.icon});
  final Color color;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            icon,
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ─── Menu ─────────────────────────────────────────────────────────────────────

class _BotMenu extends StatelessWidget {
  const _BotMenu({
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 18, color: KTokens.inkSoft),
      splashRadius: 16,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Text('Configurar', style: GoogleFonts.inter(fontSize: 13)),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Text('Duplicar', style: GoogleFonts.inter(fontSize: 13)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Eliminar',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: KTokens.excClosed,
            ),
          ),
        ),
      ],
      onSelected: (v) {
        switch (v) {
          case 'edit':
            onEdit();
          case 'duplicate':
            onDuplicate();
          case 'delete':
            onDelete();
        }
      },
    );
  }
}
