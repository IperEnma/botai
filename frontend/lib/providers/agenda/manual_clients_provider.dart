import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/agenda/panels/booking_wizard/booking_draft.dart';

class ManualClientsNotifier extends Notifier<List<BookingCliente>> {
  @override
  List<BookingCliente> build() => const [];

  void add(BookingCliente c) {
    state = [...state, c];
  }
}

// Not autoDispose — persists for the lifetime of the app session.
final manualClientsProvider =
    NotifierProvider<ManualClientsNotifier, List<BookingCliente>>(
  ManualClientsNotifier.new,
);
