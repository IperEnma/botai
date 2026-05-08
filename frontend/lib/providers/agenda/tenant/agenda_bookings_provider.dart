import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/booking.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

typedef AgendaBookingsKey = ({String businessId, DateTime day});

final agendaBookingsProvider =
    FutureProvider.autoDispose.family<List<Booking>, AgendaBookingsKey>(
        (ref, key) async {
  final api = ref.read(agendaApiServiceProvider);
  final start = DateTime(key.day.year, key.day.month, key.day.day, 0, 0, 0);
  final end = DateTime(key.day.year, key.day.month, key.day.day, 23, 59, 59);
  try {
    return await api.businessAgendaBookings(
      businessId: key.businessId,
      from: start,
      to: end,
    );
  } on AgendaApiException {
    rethrow;
  }
});

