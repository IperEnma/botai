import '../../../models/agenda/service_scheduling_mode.dart';

class ServicioItem {
  final String id;
  final String name;
  final String? description;
  final int durationMinutes;
  final bool flexibleDuration;
  final int priceUyu;
  final bool priceFrom;
  bool active;
  final ServiceSchedulingMode schedulingMode;
  final List<String> professionalIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServicioItem({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    this.flexibleDuration = false,
    required this.priceUyu,
    this.priceFrom = false,
    this.active = true,
    this.schedulingMode = ServiceSchedulingMode.general,
    this.professionalIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get usesStaffScheduling =>
      schedulingMode == ServiceSchedulingMode.byStaff;

  ServicioItem copyWith({
    String? name,
    String? description,
    int? durationMinutes,
    bool? flexibleDuration,
    int? priceUyu,
    bool? priceFrom,
    bool? active,
    ServiceSchedulingMode? schedulingMode,
    List<String>? professionalIds,
  }) =>
      ServicioItem(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        flexibleDuration: flexibleDuration ?? this.flexibleDuration,
        priceUyu: priceUyu ?? this.priceUyu,
        priceFrom: priceFrom ?? this.priceFrom,
        active: active ?? this.active,
        schedulingMode: schedulingMode ?? this.schedulingMode,
        professionalIds: professionalIds ?? this.professionalIds,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
