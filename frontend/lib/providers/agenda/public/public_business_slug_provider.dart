import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/agenda_service.dart';
import '../../../models/agenda/availability_slot.dart';
import '../../../models/agenda/business.dart';
import '../../../models/agenda/staff_member.dart';
import '../agenda_api_provider.dart';

final publicBusinessBySlugProvider =
    FutureProvider.autoDispose.family<Business, String>((ref, slug) {
  final api = ref.watch(agendaApiServiceProvider);
  return api.publicBusinessDetailBySlug(slug);
});

final publicBusinessServicesBySlugProvider =
    FutureProvider.autoDispose.family<List<AgendaService>, String>((ref, slug) {
  final api = ref.watch(agendaApiServiceProvider);
  return api.publicBusinessServicesBySlug(slug);
});

final publicStaffBySlugProvider =
    FutureProvider.autoDispose.family<List<StaffMember>, String>((ref, slug) {
  final api = ref.watch(agendaApiServiceProvider);
  return api.publicBusinessStaffBySlug(slug);
});

typedef AvailabilitySlugKey = ({
  String slug,
  String serviceId,
  String? staffMemberId,
  String date,
});

final availabilityBySlugProvider = FutureProvider.autoDispose
    .family<List<AvailabilitySlot>, AvailabilitySlugKey>((ref, k) {
  final api = ref.watch(agendaApiServiceProvider);
  return api.publicAvailabilityBySlug(
    slug: k.slug,
    serviceId: k.serviceId,
    staffMemberId: k.staffMemberId,
    date: k.date,
  );
});

