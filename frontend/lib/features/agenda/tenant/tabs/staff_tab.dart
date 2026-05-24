import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../equipo/screens/equipo_screen.dart';

class StaffTab extends ConsumerWidget {
  const StaffTab({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EquipoScreen(tenantId: tenantId, businessId: businessId);
  }
}
