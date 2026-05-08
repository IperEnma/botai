import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/staff_member.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class BusinessStaffState {
  final List<StaffMember> members;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const BusinessStaffState({
    this.members = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  BusinessStaffState copyWith({
    List<StaffMember>? members,
    bool? isLoading,
    bool? isSaving,
    Object? error = _sentinel,
  }) {
    return BusinessStaffState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

typedef _StaffKey = ({String tenantId, String businessId});

class BusinessStaffNotifier extends StateNotifier<BusinessStaffState> {
  BusinessStaffNotifier(this._ref, this._key)
      : super(const BusinessStaffState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final _StaffKey _key;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final members = await api.getStaffMembers(
        businessId: _key.businessId,
      );
      state = BusinessStaffState(members: members);
    } on AgendaApiException catch (e) {
      state = BusinessStaffState(error: e.message);
    }
  }

  Future<StaffMember?> addMember(String nombre, String? rol, String? avatarUrl) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final member = await api.createStaffMember(
        businessId: _key.businessId,
        nombre: nombre,
        rol: rol,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(
        members: [...state.members, member],
        isSaving: false,
      );
      return member;
    } on AgendaApiException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return null;
    }
  }

  Future<bool> updateMember(
    String staffId,
    String nombre,
    String? rol,
    String? avatarUrl,
    bool activo,
  ) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final updated = await api.updateStaffMember(
        businessId: _key.businessId,
        staffId: staffId,
        nombre: nombre,
        rol: rol,
        avatarUrl: avatarUrl,
        activo: activo,
      );
      state = state.copyWith(
        members: state.members.map((m) => m.id == staffId ? updated : m).toList(),
        isSaving: false,
      );
      return true;
    } on AgendaApiException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    }
  }

  Future<bool> uploadAvatar(String staffId, List<int> bytes, String fileName) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final url = await api.uploadStaffAvatar(
        businessId: _key.businessId,
        staffId: staffId,
        bytes: bytes,
        fileName: fileName,
      );
      final member = state.members.firstWhere((m) => m.id == staffId);
      final updated = await api.updateStaffMember(
        businessId: _key.businessId,
        staffId: staffId,
        nombre: member.nombre,
        rol: member.rol,
        avatarUrl: url,
        activo: member.activo,
      );
      state = state.copyWith(
        members: state.members.map((m) => m.id == staffId ? updated : m).toList(),
        isSaving: false,
      );
      return true;
    } on AgendaApiException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    }
  }

  Future<void> deactivate(String staffId) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      await api.deleteStaffMember(
        businessId: _key.businessId,
        staffId: staffId,
      );
      state = state.copyWith(
        members: state.members.where((m) => m.id != staffId).toList(),
        isSaving: false,
      );
    } on AgendaApiException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
    }
  }
}

final businessStaffProvider = StateNotifierProvider.autoDispose
    .family<BusinessStaffNotifier, BusinessStaffState, _StaffKey>(
  (ref, key) => BusinessStaffNotifier(ref, key),
);
