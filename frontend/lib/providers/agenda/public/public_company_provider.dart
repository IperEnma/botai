import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/public_company.dart';
import '../agenda_api_provider.dart';

final publicCompanyProvider =
    FutureProvider.autoDispose.family<PublicCompany, String>((ref, companySlug) {
  final api = ref.watch(agendaApiServiceProvider);
  return api.publicCompanyDetail(companySlug);
});
