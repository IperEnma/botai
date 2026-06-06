import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bot.dart';

const _mockPlan = BusinessPlan(
  tier: 'profesional',
  displayName: 'Profesional',
  capa: BotCapa.capa2,
  monthlyMsgQuota: 0,
  usedMsgsThisMonth: 0,
);

final businessPlanProvider = Provider<BusinessPlan>((ref) => _mockPlan);
