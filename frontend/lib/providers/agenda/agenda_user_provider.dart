import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config.dart';

class AgendaUserState {
  const AgendaUserState({this.tenantId});
  final String? tenantId;
  bool get hasBusiness => tenantId != null;
}

class AgendaUserNotifier extends AsyncNotifier<AgendaUserState> {
  static const _kTenantId = 'agenda_tenant_id';

  @override
  Future<AgendaUserState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kTenantId);
    // Fall back to dev env override when no registered tenant is stored.
    final tenantId = saved ?? AppConfig.agendaDefaultTenantId;
    return AgendaUserState(tenantId: tenantId);
  }

  Future<void> saveTenantId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTenantId, id);
    state = AsyncData(AgendaUserState(tenantId: id));
  }
}

final agendaUserProvider =
    AsyncNotifierProvider<AgendaUserNotifier, AgendaUserState>(
        AgendaUserNotifier.new);
