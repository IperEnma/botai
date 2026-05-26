import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bot.dart';

const _mockPlan = BusinessPlan(
  tier: 'profesional',
  displayName: 'Profesional',
  capa: BotCapa.capa2,
  monthlyMsgQuota: 1000,
  usedMsgsThisMonth: 248,
);

final businessPlanProvider = Provider<BusinessPlan>((ref) => _mockPlan);
