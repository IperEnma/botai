import 'package:flutter/material.dart';

import '../../../models/bot.dart' show BotTier;

// ─── Enums ────────────────────────────────────────────────────────────────────

enum BotCapa { capa1, capa2, capa3 }

enum BotChannel { whatsapp, telegram, web, instagram }

// ─── Business plan ────────────────────────────────────────────────────────────

class BusinessPlan {
  final String tier;
  final String displayName;
  final BotCapa capa;
  final int monthlyMsgQuota;
  final int usedMsgsThisMonth;

  const BusinessPlan({
    required this.tier,
    required this.displayName,
    required this.capa,
    required this.monthlyMsgQuota,
    required this.usedMsgsThisMonth,
  });

  double get usagePct => usedMsgsThisMonth / monthlyMsgQuota;
}

// ─── Helpers: Tier <-> Capa ───────────────────────────────────────────────────

BotCapa capaFromTier(BotTier tier) => switch (tier) {
      BotTier.tier1 => BotCapa.capa1,
      BotTier.tier2 => BotCapa.capa2,
      BotTier.tier3 => BotCapa.capa3,
    };

BotTier tierFromCapa(BotCapa capa) => switch (capa) {
      BotCapa.capa1 => BotTier.tier1,
      BotCapa.capa2 => BotTier.tier2,
      BotCapa.capa3 => BotTier.tier3,
    };

Color colorForCapa(BotCapa capa) => switch (capa) {
      BotCapa.capa1 => const Color(0xFFA78BFA),
      BotCapa.capa2 => const Color(0xFF34D399),
      BotCapa.capa3 => const Color(0xFFFB923C),
    };

const _kAvatarIcons = ['◐', '◑', '◒', '◓', '★', '◆'];

String iconForBot(String name) => name.isEmpty
    ? _kAvatarIcons[0]
    : _kAvatarIcons[name.codeUnitAt(0) % _kAvatarIcons.length];
