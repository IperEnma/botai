import 'package:flutter/material.dart';

import '../../panels/booking_wizard/booking_wizard_panel.dart';

/// Shows the "Agendá un cliente" wizard panel.
/// Delegates entirely to [showBookingWizardPanel]; kept for backwards compatibility.
Future<void> showNewTurnoPanel(
  BuildContext context, {
  required String tenantId,
  required String businessId,
  DateTime? initialDate,
  String? initialProId,
}) {
  return showBookingWizardPanel(
    context,
    tenantId: tenantId,
    businessId: businessId,
    initialDate: initialDate,
    initialProId: initialProId,
  );
}
