import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/booking.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class BookingsState {
  final List<Booking> items;
  final bool isLoading;
  final String? error;

  const BookingsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  BookingsState copyWith({
    List<Booking>? items,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return BookingsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

typedef _BookingsKey = ({String? tenantId, String? businessId});

class BookingsNotifier extends StateNotifier<BookingsState> {
  BookingsNotifier(this._ref, this._key)
      : super(const BookingsState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final _BookingsKey _key;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final items = await api.myBookings(
        tenantId: _key.tenantId,
        businessId: _key.businessId,
      );
      state = BookingsState(items: items);
    } on AgendaApiException catch (e) {
      state = BookingsState(error: e.message);
    }
  }

  Future<Booking> create({
    required String tenantId,
    required String businessId,
    required String serviceId,
    required DateTime fechaHoraInicio,
    BookingTipo tipoReserva = BookingTipo.pagoPorTurno,
    String? subscriptionId,
    String? notas,
    String? idempotencyKey,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    final created = await api.createBooking(
      tenantId: tenantId,
      businessId: businessId,
      serviceId: serviceId,
      fechaHoraInicio: fechaHoraInicio,
      tipoReserva: tipoReserva,
      subscriptionId: subscriptionId,
      notas: notas,
      idempotencyKey: idempotencyKey,
    );
    state = state.copyWith(items: [...state.items, created]);
    return created;
  }

  Future<void> cancel({
    required String tenantId,
    required String businessId,
    required String bookingId,
  }) async {
    final api = _ref.read(agendaApiServiceProvider);
    await api.cancelBooking(
      tenantId: tenantId,
      businessId: businessId,
      bookingId: bookingId,
    );
    state = state.copyWith(
      items: state.items
          .map((b) => b.id == bookingId
              ? b.copyWith(estado: BookingEstado.cancelada)
              : b)
          .toList(),
    );
  }
}

final bookingsProvider = StateNotifierProvider.autoDispose
    .family<BookingsNotifier, BookingsState, _BookingsKey>((ref, key) {
  return BookingsNotifier(ref, key);
});
