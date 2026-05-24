import 'package:flutter/material.dart';

import '../../../servicios/screens/servicios_screen.dart';

class ServicesTab extends StatelessWidget {
  const ServicesTab({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context) {
    return ServiciosScreen(tenantId: tenantId, businessId: businessId);
  }
}
