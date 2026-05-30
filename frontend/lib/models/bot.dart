enum BotTier { tier1, tier2, tier3 }

class Bot {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final BotTier tier;
  final String? whatsappPhoneNumberId;
  final String? whatsappAccessToken;
  final bool whatsappAccessTokenConfigured;
  final String? whatsappVerifyToken;
  final bool faqEnabled;
  final bool aiEnabled;
  final bool actionsEnabled;
  /// IDs de sucursales Agenda (`agenda_businesses.id`). Obligatorio al crear bot (backend).
  final List<String> linkedAgendaBusinessIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Bot({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    required this.tier,
    this.whatsappPhoneNumberId,
    this.whatsappAccessToken,
    this.whatsappAccessTokenConfigured = false,
    this.whatsappVerifyToken,
    this.faqEnabled = true,
    this.aiEnabled = false,
    this.actionsEnabled = false,
    this.linkedAgendaBusinessIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
    return Bot(
      id: _parseId(json['id']),
      tenantId: json['tenantId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      tier: _parseTier(json['tier']),
      whatsappPhoneNumberId: _toStringOrNull(json['whatsappPhoneNumberId']),
      whatsappAccessToken: null,
      whatsappAccessTokenConfigured:
          json['whatsappAccessTokenConfigured'] as bool? ??
              (_toStringOrNull(json['whatsappAccessToken']) != null),
      whatsappVerifyToken: _toStringOrNull(json['whatsappVerifyToken']),
      faqEnabled: json['faqEnabled'] as bool? ?? true,
      aiEnabled: json['aiEnabled'] as bool? ?? false,
      actionsEnabled: json['actionsEnabled'] as bool? ?? false,
      linkedAgendaBusinessIds: _parseUuidStringList(json['linkedAgendaBusinessIds']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updatedAt']),
    );
  }

  static List<String> _parseUuidStringList(dynamic value) {
    if (value == null) return const [];
    if (value is! List<dynamic>) return const [];
    return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  static String _parseId(dynamic value) {
    if (value == null) return '';
    if (value is int) return value.toString();
    return value.toString();
  }

  /// Acepta string o número del backend (evita null si viene como número).
  static String? _toStringOrNull(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static BotTier _parseTier(dynamic value) {
    if (value == null) return BotTier.tier1;
    final s = value.toString();
    for (final e in BotTier.values) {
      if (e.name == s) return e;
    }
    return BotTier.tier1;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'tenantId': tenantId,
      'name': name,
      'description': description,
      'tier': tier.name,
      'whatsappPhoneNumberId': whatsappPhoneNumberId,
      if (whatsappAccessToken != null && whatsappAccessToken!.isNotEmpty)
        'whatsappAccessToken': whatsappAccessToken,
      'faqEnabled': faqEnabled,
      'aiEnabled': aiEnabled,
      'actionsEnabled': actionsEnabled,
      if (linkedAgendaBusinessIds.isNotEmpty)
        'linkedAgendaBusinessIds': linkedAgendaBusinessIds,
    };
  }

  Bot copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? description,
    BotTier? tier,
    String? whatsappPhoneNumberId,
    String? whatsappAccessToken,
    bool? whatsappAccessTokenConfigured,
    String? whatsappVerifyToken,
    bool? faqEnabled,
    bool? aiEnabled,
    bool? actionsEnabled,
    List<String>? linkedAgendaBusinessIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bot(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      tier: tier ?? this.tier,
      whatsappPhoneNumberId: whatsappPhoneNumberId ?? this.whatsappPhoneNumberId,
      whatsappAccessToken: whatsappAccessToken ?? this.whatsappAccessToken,
      whatsappAccessTokenConfigured:
          whatsappAccessTokenConfigured ?? this.whatsappAccessTokenConfigured,
      whatsappVerifyToken: whatsappVerifyToken ?? this.whatsappVerifyToken,
      faqEnabled: faqEnabled ?? this.faqEnabled,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      actionsEnabled: actionsEnabled ?? this.actionsEnabled,
      linkedAgendaBusinessIds: linkedAgendaBusinessIds ?? this.linkedAgendaBusinessIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get tierLabel {
    switch (tier) {
      case BotTier.tier1:
        return 'Capa 1 - FAQ';
      case BotTier.tier2:
        return 'Capa 2 - IA Híbrida';
      case BotTier.tier3:
        return 'Capa 3 - IA + CRM';
    }
  }
}

