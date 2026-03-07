enum BotTier { tier1, tier2, tier3 }

class Bot {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final BotTier tier;
  final String? whatsappPhoneNumberId;
  final String? whatsappAccessToken;
  final String? whatsappVerifyToken;
  final bool faqEnabled;
  final bool aiEnabled;
  final bool actionsEnabled;
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
    this.whatsappVerifyToken,
    this.faqEnabled = true,
    this.aiEnabled = false,
    this.actionsEnabled = false,
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
      whatsappPhoneNumberId: json['whatsappPhoneNumberId'] as String?,
      whatsappAccessToken: json['whatsappAccessToken'] as String?,
      whatsappVerifyToken: json['whatsappVerifyToken'] as String?,
      faqEnabled: json['faqEnabled'] as bool? ?? true,
      aiEnabled: json['aiEnabled'] as bool? ?? false,
      actionsEnabled: json['actionsEnabled'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updatedAt']),
    );
  }

  static String _parseId(dynamic value) {
    if (value == null) return '';
    if (value is int) return value.toString();
    return value.toString();
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
      'whatsappAccessToken': whatsappAccessToken,
      'whatsappVerifyToken': whatsappVerifyToken,
      'faqEnabled': faqEnabled,
      'aiEnabled': aiEnabled,
      'actionsEnabled': actionsEnabled,
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
    String? whatsappVerifyToken,
    bool? faqEnabled,
    bool? aiEnabled,
    bool? actionsEnabled,
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
      whatsappVerifyToken: whatsappVerifyToken ?? this.whatsappVerifyToken,
      faqEnabled: faqEnabled ?? this.faqEnabled,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      actionsEnabled: actionsEnabled ?? this.actionsEnabled,
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

