import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/booking.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

typedef AgendaWeekKey = ({String businessId, DateTime weekStart});

final agendaWeekBookingsProvider =
    FutureProvider.autoDispose.family<List<Booking>, AgendaWeekKey>(
        (ref, key) async {
  final api = ref.read(agendaApiServiceProvider);
  final ws = key.weekStart;
  final from = DateTime(ws.year, ws.month, ws.day, 0, 0, 0);
  final weekEnd = ws.add(const Duration(days: 6));
  final to = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);
  try {
    return await api.businessAgendaBookings(
      businessId: key.businessId,
      from: from,
      to: to,
    );
  } on AgendaApiException {
    rethrow;
  }
});
