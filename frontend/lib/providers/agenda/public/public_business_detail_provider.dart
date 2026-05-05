import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/availability_slot.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/staff_member.dart';
import '../agenda_api_provider.dart';

final publicBusinessProvider =
    FutureProvider.autoDispose.family<Business, String>((ref, id) {
  final api = ref.watch(agendaApiServiceProvider);
  return api.publicBusinessDetail(id);
});

final publicBusinessServicesProvider =
    FutureProvider.autoDispose.family<List<AgendaService>, String>((ref, id) {
  final api = ref.watch(agendaApiServiceProvider);
  return api.publicBusinessServices(id);
});

final publicStaffProvider =
    FutureProvider.autoDispose.family<List<StaffMember>, String>((ref, id) {
  final api = ref.watch(agendaApiServiceProvider);
  return api.publicBusinessStaff(id);
});

typedef AvailabilityKey = ({
  String businessId,
  String serviceId,
  String? staffMemberId,
  String date,
});

final availabilityProvider = FutureProvider.autoDispose
    .family<List<AvailabilitySlot>, AvailabilityKey>((ref, k) {
  final api = ref.watch(agendaApiServiceProvider);
  return api.publicAvailability(
    businessId: k.businessId,
    serviceId: k.serviceId,
    staffMemberId: k.staffMemberId,
    date: k.date,
  );
});
