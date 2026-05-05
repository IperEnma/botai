import 'agenda_json.dart';

class TenantFeatures {
  final String tenantId;
  final bool agendaEnabled;
  final bool publicSearchEnabled;
  final bool loyaltyEngineEnabled;
  final bool autoNotifications;

  const TenantFeatures({
    required this.tenantId,
    required this.agendaEnabled,
    required this.publicSearchEnabled,
    required this.loyaltyEngineEnabled,
    required this.autoNotifications,
  });

  factory TenantFeatures.fromJson(String tenantId, Map<String, dynamic> json) {
    return TenantFeatures(
      tenantId: tenantId,
      agendaEnabled: AgendaJson.parseBool(json['agendaEnabled'], fallback: true),
      publicSearchEnabled: AgendaJson.parseBool(json['publicSearchEnabled'], fallback: true),
      loyaltyEngineEnabled: AgendaJson.parseBool(json['loyaltyEngineEnabled']),
      autoNotifications: AgendaJson.parseBool(json['autoNotifications']),
    );
  }

  TenantFeatures copyWith({
    bool? agendaEnabled,
    bool? publicSearchEnabled,
    bool? loyaltyEngineEnabled,
    bool? autoNotifications,
  }) {
    return TenantFeatures(
      tenantId: tenantId,
      agendaEnabled: agendaEnabled ?? this.agendaEnabled,
      publicSearchEnabled: publicSearchEnabled ?? this.publicSearchEnabled,
      loyaltyEngineEnabled: loyaltyEngineEnabled ?? this.loyaltyEngineEnabled,
      autoNotifications: autoNotifications ?? this.autoNotifications,
    );
  }

  Map<String, dynamic> toRequestJson() => {
        'agendaEnabled': agendaEnabled,
        'publicSearchEnabled': publicSearchEnabled,
        'loyaltyEngineEnabled': loyaltyEngineEnabled,
        'autoNotifications': autoNotifications,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TenantFeatures && other.tenantId == tenantId);

  @override
  int get hashCode => tenantId.hashCode;
}
