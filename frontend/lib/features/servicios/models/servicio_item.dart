class ServicioItem {
  final String id;
  final String name;
  final String? description;
  final String groupId;
  final int durationMinutes;
  final bool flexibleDuration;
  final int priceUyu;
  final bool priceFrom;
  bool active;
  final List<String> professionalIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServicioItem({
    required this.id,
    required this.name,
    this.description,
    required this.groupId,
    required this.durationMinutes,
    this.flexibleDuration = false,
    required this.priceUyu,
    this.priceFrom = false,
    this.active = true,
    this.professionalIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  ServicioItem copyWith({
    String? name,
    String? description,
    String? groupId,
    int? durationMinutes,
    bool? flexibleDuration,
    int? priceUyu,
    bool? priceFrom,
    bool? active,
    List<String>? professionalIds,
  }) =>
      ServicioItem(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        groupId: groupId ?? this.groupId,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        flexibleDuration: flexibleDuration ?? this.flexibleDuration,
        priceUyu: priceUyu ?? this.priceUyu,
        priceFrom: priceFrom ?? this.priceFrom,
        active: active ?? this.active,
        professionalIds: professionalIds ?? this.professionalIds,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
