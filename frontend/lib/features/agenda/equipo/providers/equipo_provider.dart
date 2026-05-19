import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda/staff_member.dart';
import '../../../../providers/agenda/tenant/business_staff_provider.dart';
import '../../register/konecta_tokens.dart';
import '../models/member.dart';

typedef EquipoKey = ({String tenantId, String businessId});

// ─── State ────────────────────────────────────────────────────────────────────

class EquipoState {
  final List<Member> members;
  final String searchQuery;
  final MemberStatus? filterStatus;
  final bool isLoading;
  final String? error;

  const EquipoState({
    required this.members,
    this.searchQuery = '',
    this.filterStatus,
    this.isLoading = false,
    this.error,
  });

  List<Member> get filtered {
    var list = members;

    if (filterStatus != null) {
      list = list.where((m) => m.status == filterStatus).toList();
    }

    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((m) {
        if (m.name.toLowerCase().contains(q)) return true;
        if (m.title?.toLowerCase().contains(q) == true) return true;
        return false;
      }).toList();
    }

    return list;
  }

  int get countActivos =>
      members.where((m) => m.status == MemberStatus.activo).length;
  int get countPausados =>
      members.where((m) => m.status == MemberStatus.pausado).length;
  int get countArchivados =>
      members.where((m) => m.status == MemberStatus.archivado).length;

  int get totalTurnosHoy =>
      members.where((m) => m.status == MemberStatus.activo).fold(
            0,
            (acc, m) => acc + m.turnosHoy,
          );

  EquipoState copyWith({
    List<Member>? members,
    String? searchQuery,
    MemberStatus? filterStatus,
    bool clearFilter = false,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return EquipoState(
      members: members ?? this.members,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

// ─── Member conversion ────────────────────────────────────────────────────────

Member _toMember(StaffMember sm, int index) {
  MemberType type;
  MemberRole role;

  switch (sm.rol?.toLowerCase()) {
    case 'recepcion':
    case 'recepcionista':
      type = MemberType.recepcion;
      role = MemberRole.recepcion;
    default:
      type = MemberType.profesionalConCuenta;
      role = MemberRole.profesional;
  }

  return Member(
    id: sm.id,
    name: sm.nombre,
    type: type,
    status: sm.activo ? MemberStatus.activo : MemberStatus.archivado,
    role: role,
    color: KTokens.proPalette[index % KTokens.proPalette.length],
    avatarUrl: sm.avatarUrl,
    title: sm.rol,
    serviceIds: const [],
    joinedAt: DateTime.now(),
    turnosCompletados: 0,
    avgRating: 0,
    turnosHoy: 0,
    inviteAccepted: sm.activo,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class EquipoNotifier extends StateNotifier<EquipoState> {
  EquipoNotifier(this._ref, this._key)
      : super(const EquipoState(members: [], isLoading: true)) {
    _ref.listen<BusinessStaffState>(
      businessStaffProvider(
          (tenantId: _key.tenantId, businessId: _key.businessId)),
      (_, next) {
        if (next.isLoading) {
          state = state.copyWith(isLoading: true, error: null);
        } else if (next.error != null) {
          state = state.copyWith(isLoading: false, error: next.error);
        } else {
          final members = next.members
              .asMap()
              .entries
              .map((e) => _toMember(e.value, e.key))
              .toList();
          state =
              state.copyWith(members: members, isLoading: false, error: null);
        }
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;
  final EquipoKey _key;

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(MemberStatus? status) {
    if (status == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterStatus: status);
    }
  }

  void updateMember(Member updated) {
    final idx = state.members.indexWhere((m) => m.id == updated.id);
    if (idx < 0) return;
    final list = List<Member>.from(state.members);
    list[idx] = updated;
    state = state.copyWith(members: list);
  }

  void setStatus(String memberId, MemberStatus status) {
    final idx = state.members.indexWhere((m) => m.id == memberId);
    if (idx < 0) return;
    final list = List<Member>.from(state.members);
    list[idx] = list[idx].copyWith(status: status);
    state = state.copyWith(members: list);
  }

  void updateServiceIds(String memberId, List<String> serviceIds) {
    final idx = state.members.indexWhere((m) => m.id == memberId);
    if (idx < 0) return;
    final list = List<Member>.from(state.members);
    list[idx] = list[idx].copyWith(serviceIds: serviceIds);
    state = state.copyWith(members: list);
  }

  void addMember(Member member) {
    state = state.copyWith(members: [...state.members, member]);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final equipoProvider = StateNotifierProvider.autoDispose
    .family<EquipoNotifier, EquipoState, EquipoKey>(
  (ref, key) => EquipoNotifier(ref, key),
);
