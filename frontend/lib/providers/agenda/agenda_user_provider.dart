import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config.dart';

class AgendaUserState {
  const AgendaUserState({this.tenantId, this.nombre});
  final String? tenantId;
  final String? nombre;
  bool get hasBusiness => tenantId != null;
}

class AgendaUserNotifier extends AsyncNotifier<AgendaUserState> {
  static const _kTenantId = 'agenda_tenant_id';
  static const _kNombre   = 'agenda_user_nombre';

  @override
  Future<AgendaUserState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId = prefs.getString(_kTenantId) ?? AppConfig.agendaDefaultTenantId;
    final nombre   = prefs.getString(_kNombre);
    return AgendaUserState(tenantId: tenantId, nombre: nombre);
  }

  Future<void> saveTenantId(String id) async {
    final prefs  = await SharedPreferences.getInstance();
    await prefs.setString(_kTenantId, id);
    final nombre = prefs.getString(_kNombre);
    state = AsyncData(AgendaUserState(tenantId: id, nombre: nombre));
  }

  Future<void> saveNombre(String nombre) async {
    final prefs    = await SharedPreferences.getInstance();
    await prefs.setString(_kNombre, nombre);
    final tenantId = prefs.getString(_kTenantId) ?? AppConfig.agendaDefaultTenantId;
    state = AsyncData(AgendaUserState(tenantId: tenantId, nombre: nombre));
  }
}

final agendaUserProvider =
    AsyncNotifierProvider<AgendaUserNotifier, AgendaUserState>(
        AgendaUserNotifier.new);
