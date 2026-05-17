import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/booking.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

typedef AgendaMonthKey = ({String businessId, int year, int month});

final agendaMonthBookingsProvider =
    FutureProvider.autoDispose.family<List<Booking>, AgendaMonthKey>(
        (ref, key) async {
  final api = ref.read(agendaApiServiceProvider);
  final from = DateTime(key.year, key.month, 1, 0, 0, 0);
  final to = DateTime(key.year, key.month + 1, 0, 23, 59, 59);
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
