import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config.dart';

class AgendaUserState {
  const AgendaUserState({this.tenantId, this.nombre, this.phone});
  final String? tenantId;
  final String? nombre;
  final String? phone;
  bool get hasBusiness => tenantId != null;
}

class AgendaUserNotifier extends AsyncNotifier<AgendaUserState> {
  static const _kTenantId = 'agenda_tenant_id';
  static const _kNombre   = 'agenda_user_nombre';
  static const _kPhone    = 'agenda_user_phone';

  @override
  Future<AgendaUserState> build() async {
    final prefs    = await SharedPreferences.getInstance();
    final tenantId = prefs.getString(_kTenantId) ?? AppConfig.agendaDefaultTenantId;
    final nombre   = prefs.getString(_kNombre);
    final phone    = prefs.getString(_kPhone);
    return AgendaUserState(tenantId: tenantId, nombre: nombre, phone: phone);
  }

  Future<void> saveTenantId(String id) async {
    final prefs  = await SharedPreferences.getInstance();
    await prefs.setString(_kTenantId, id);
    final current = state.valueOrNull;
    state = AsyncData(AgendaUserState(
      tenantId: id,
      nombre: current?.nombre,
      phone: current?.phone,
    ));
  }

  Future<void> saveNombre(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNombre, nombre);
    final current = state.valueOrNull;
    state = AsyncData(AgendaUserState(
      tenantId: current?.tenantId ?? AppConfig.agendaDefaultTenantId,
      nombre: nombre,
      phone: current?.phone,
    ));
  }

  Future<void> savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhone, phone);
    final current = state.valueOrNull;
    state = AsyncData(AgendaUserState(
      tenantId: current?.tenantId ?? AppConfig.agendaDefaultTenantId,
      nombre: current?.nombre,
      phone: phone,
    ));
  }

  Future<void> saveRegistrationData({
    required String nombre,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNombre, nombre);
    await prefs.setString(_kPhone, phone);
    final current = state.valueOrNull;
    state = AsyncData(AgendaUserState(
      tenantId: current?.tenantId ?? AppConfig.agendaDefaultTenantId,
      nombre: nombre,
      phone: phone,
    ));
  }
}

final agendaUserProvider =
    AsyncNotifierProvider<AgendaUserNotifier, AgendaUserState>(
        AgendaUserNotifier.new);
